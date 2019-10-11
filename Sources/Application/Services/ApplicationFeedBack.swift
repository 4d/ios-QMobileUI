//
//  ApplicationFeedBack.swift
//  QMobileUI
//
//  Created by Eric Marchand on 16/07/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

import XCGLogger
import Prephirences
import FileKit
import DeviceKit

import MessageUI

class ApplicationFeedback: NSObject {

    var shakeListener: AnyObject?
    var inShake: Bool = false
    var window: UIWindow?

}

extension ApplicationFeedback: ApplicationService {

    static var instance: ApplicationService = ApplicationFeedback()

    static var pref: MutablePreferencesType {
        return MutableProxyPreferences(preferences: preferences, key: "feedback.")
    }

    public static var showFeedback: Bool { // dynamic value, could be changed from setting, do not setore it
        get {
            return true // pref["show"] as? Bool ?? false
        }
        set {
            pref.set(newValue, forKey: "show")
        }
    }

    public static var showComposeOption: Bool {
        return pref["compose"] as? Bool ?? true
    }

    fileprivate func feedbackWhenGoToFront() {
        if ApplicationFeedback.showFeedback {
            self.showDialog(tips: "Feedback activated by setting",
                            presented: { ApplicationFeedback.showFeedback = false },
                            completion: { logger.debug("Feedback dialog completed") }
            )
        }
    }

    // swiftlint:disable:next function_body_length
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        let pref = ApplicationFeedback.pref

        let eventPref: Preference<FeedbackEvent> = pref.preference(forKey: "event")
        #if DEBUG
        let event = eventPref.value ?? .shake
        #else
        let event = eventPref.value ?? .none
        #endif

        // MARK: register to event
        let center = NotificationCenter.default

        switch event {
        case .shake:
            application.applicationSupportsShakeToEdit = true
            shakeListener = center.addObserver(forName: .motionShakeEnd, object: nil, queue: .main) { [weak self] _ in
                guard let strongSelf = self else {
                    return
                }
                if !strongSelf.inShake {
                    strongSelf.inShake = true
                    strongSelf.showDialog(tips: "💡 Shake the device to display this dialog again.") {
                        strongSelf.inShake = false
                    }
                }
            }
       /* case .screenshot:
            shakeListener = center.addObserver(forName: .UIApplicationUserDidTakeScreenshot, object: nil, queue: .main) { [weak self] _ in
             self?.showLogSendDialog()
             }*/
        case .none:
            logger.info("Feedback not activated by automatic action.")
        }

        feedbackWhenGoToFront()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        if let shakeListener = shakeListener {
            NotificationCenter.default.removeObserver(shakeListener)
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        feedbackWhenGoToFront()
    }

    func showDialog(tips: String, presented: (() -> Swift.Void)? = nil, completion: (() -> Swift.Void)? = nil) { // swiftlint:disable:this function_body_length
        // tips must depend of parent event
        let alert = UIAlertController(title: "How can we help you?",
                                      message: tips,
                                      preferredStyle: .actionSheet)
        let completion: (() -> Swift.Void) = {
            completion?()
            self.window = nil // free window on completion. must keep a reference on window to no be dismissed automatically
        }
        if ApplicationFeedback.showComposeOption {
            alert.addAction(UIAlertAction(title: "💬 Talk to us", style: .default, handler: { _ in
                self.showFeedbackForm(subject: "Talk to us", body: "here sugest improvement", attachLogs: false, completion: completion)
            }))
            alert.addAction(UIAlertAction(title: "📣 Suggest an improvement", style: .default, handler: { _ in
                self.showFeedbackForm(subject: "Suggest an improvement", body: "here suggest improvement", attachLogs: false, completion: completion)
            }))
        }

        alert.addAction(UIAlertAction(title: "📄 Show current log", style: .default, handler: { _ in
            guard let topVC = UIApplication.topViewController else {
                logger.error("No view controller to show log")
                return
            }
            if let logForm = LogForm.instantiate() {
                logForm.path = ApplicationLogger.currentLog
                topVC.show(logForm.navigationController ?? logForm, sender: topVC)
            }
            completion()
        }))

        if ApplicationFeedback.isConfigured {
            alert.addAction(UIAlertAction(title: "🐞 Report a problem", style: .destructive, handler: { _ in
                self.showFeedbackForm(subject: "Report a problem", body: "What went wrong?", attachLogs: true, completion: completion)
            }))
        }

        var feedback = Feedback()
        feedback.title = "Report a problem"
        feedback.summaryPlaceholder = "What went wrong?"

        if ApplicationCrashManager.pref["me"] as? Bool ?? false {
            alert.addAction(UIAlertAction(title: "💣 Crash me", style: .destructive, handler: { _ in
                if ApplicationCrashManager.pref["me.throw"] as? Bool ?? false {
                    self.throwMe()
                } else {
                    self.crashMe()
                }
                completion()
            }))
        }

        if ApplicationCrashManager.isConfigured {
            let crashs = ApplicationCrashManager.crash()
            if !crashs.isEmpty {
                alert.addAction(UIAlertAction(title: "📤 Report previous crash", style: .destructive, handler: { _ in
                    (ApplicationCrashManager.instance as? ApplicationCrashManager)?.send(crashs: crashs)
                     completion()
                }))
            }
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            completion() // XXX find a way to listen to dismiss, and do not put in each action...
        }))
        self.window = alert.presentOnTop(completion: presented)
    }

    static var isConfigured: Bool {
        return ApplicationCrashManager.isConfigured // We use same server as crash management do
    }

    /// Force crash
    private func crashMe() {
        _ = [Any]()[13]
    }

    private func throwMe() {
       NSException(name: .genericException, reason: "throw me testing", userInfo: nil).raise()
    }

    func showFeedbackForm(subject: String, body: String, attachLogs: Bool, completion: (() -> Swift.Void)? = nil) {
        guard let topVC = UIApplication.topViewController else {
            logger.error("No view controller to show log")
            return
        }
        if let form = FeedbackForm.instantiate() {
            form.delegate = self
            var feedback = Feedback()
            feedback.title = subject
            feedback.summaryPlaceholder = body
            if attachLogs {
                feedback.attach = { // attach log
                    let zipPath: Path = .userTemporary + "logs_\(DateFormatter.now()).zip"
                    if !ApplicationLogger.compressAllLog(to: zipPath) {
                        logger.error("Failed to compress the logs")
                    }
                    return zipPath
                }
            }
            if #available(iOS 13.0, *) {
                form.isModalInPresentation = true
            }
            form.feedback = feedback
            topVC.show(form.navigationController ?? form, sender: topVC)

        } else {
            self.mailCompose(subject: subject, body: "What went wrong?", attachLog: true) // Alternative by mail
        }
        completion?()
    }
}

extension ApplicationFeedback: FeedbackFormDelegate {

    func send(feedback: Feedback, dismiss: @escaping (Bool) -> Void) {
        logger.debug("prepare attached files")
        let path = feedback.attach?() ?? .userTemporary + "empty.txt"
        if !path.exists {
            try? path.touch() // touch file because server maybe wait for attachment everytime
        }
        logger.debug(" attached files prepared")

        var applicationInformation = QApplication.applicationInformation
        applicationInformation["email"] = feedback.email ?? ""
        applicationInformation["summary"] = feedback.summary ?? ""

        applicationInformation["fileName"] = path.fileName
        applicationInformation["SendDate"] = DateFormatter.now(with: "dd_MM_yyyy_HH_mm_ss")
        applicationInformation["isCrash"] = "0"

        guard let manager = ApplicationCrashManager.instance as? ApplicationCrashManager else {
            logger.warning("No manager to send files")
            return
        }
        manager.send(file: path, parameters: applicationInformation) { success in
            if success {
                logger.info("Report send")
                dismiss(true/*animated*/)
            } else {
                logger.warning("Failed to send report")
            }
            if path.exists, feedback.deleteAttach {
                try? path.deleteFile()
            }
        }
    }

    func discard(feedback: Feedback?) {
        logger.info("Report discarded")
    }

}

extension ApplicationFeedback: MFMailComposeViewControllerDelegate {

    func showSendMailErrorAlert(toRecipient: String) {
        let message: String
        if Device.current.isSimulator {
            message = "Email could not be set up using simulator."
        } else {
            message = "Make sure that you have at least one email account set up."
        }
        let alert = UIAlertController(title: "Could Not Send Email",
                                      message: message,
                                      preferredStyle: .alert)
        if !Device.current.isSimulator {
            alert.addAction(UIAlertAction(title: "📧 Open Mail app", style: .default, handler: { _ in
                if let url = URL(string: "mailto:\(toRecipient)") {
                    UIApplication.shared.open(url)
                }
            }))
        }
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))

        self.window = alert.presentOnTop()
    }

    func mailCompose(subject: String, body: String, isBodyHTML: Bool = false, attachLog: Bool = false, screenshot: Bool = false, toRecipient: String = "eric.marchand@4d.com") {
        guard MFMailComposeViewController.canSendMail() else {
            logger.info("Mail services are not available")
            showSendMailErrorAlert(toRecipient: toRecipient)
            return
        }

        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        mailComposerVC.setToRecipients([toRecipient])
        mailComposerVC.setSubject(subject)
        mailComposerVC.setMessageBody(body, isHTML: isBodyHTML)

        // mailComposerVC.setPreferredSendingEmailAddress()

        if attachLog {
            let zipPath: Path = .userTemporary + "logs_\(DateFormatter.now()).zip"
            if ApplicationLogger.compressAllLog(to: zipPath) {
                let zipFile = File<Data>(path: zipPath)
                do {
                    let data = try zipFile.read()
                    mailComposerVC.addAttachmentData(data, mimeType: "application/zip", fileName: zipPath.fileName)
                } catch {
                    logger.warning("Failed to read log data \(error)")
                }
            }
            if screenshot, let image = UIApplication.shared.keyWindow?.rootViewController?.view?.window?.screenshot() {
                if let data = image.pngData() {
                    mailComposerVC.addAttachmentData(data, mimeType: "application/png", fileName: "screenshot.jpg")
                }
            }

            if zipPath.exists {
                try? zipPath.deleteFile()
            }
        }

        self.window = mailComposerVC.presentOnTop()
    }

    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        logger.info("Mail \(result)")
        if let error = error {
            logger.error("Mail: \(error)")
        }
    }
}

// MARk: Feedback

public struct Feedback {

    init() {
    }

    var title: String?
    var summaryPlaceholder: String?
    var attach: (() -> Path)?
    var deleteAttach: Bool = true

    var email: String?
    var summary: String?
}

enum FeedbackEvent: String {
    case shake
    /*
     case screenshot
     case floatingButton
     case twoFindersSwipeLeft, rightEdgePan // some gestures
     */
    case none
}

// MARK: Screenshot

extension UIView {

    func screenshot() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, self.isOpaque, UIScreen.main.scale)
        drawHierarchy(in: bounds, afterScreenUpdates: true)
        // self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

 // detect screenshot by user
/*
import Photos

class ScreenshotDetector: NSObject /*to listen to photo lib*/ {

    enum Error: Swift.Error {
        case unauthorized(status: PHAuthorizationStatus)
        case fetchFailure
        case loadFailure
    }

    open var detectionEnabled: Bool {
        didSet {
            setupListener()
        }
    }

    private let notificationCenter: NotificationCenter
    private let application: UIApplication
    private let imageManager: PHImageManager?
    fileprivate let photoLibrary: PHPhotoLibrary
    var handler: (Result<UIImage, ScreenshotDetector.Error>) -> Void

    var listener: AnyObject?

    public init(notificationCenter: NotificationCenter = .default,
                application: UIApplication = .shared,
                imageManager: PHImageManager? = nil, /* will use default one*/
                photoLibrary: PHPhotoLibrary = .shared(),
                detectionEnabled: Bool = true,
                handler: @escaping (Result<UIImage, ScreenshotDetector.Error>) -> Void) {

        self.notificationCenter = notificationCenter
        self.application = application
        self.imageManager = imageManager
        self.photoLibrary = photoLibrary
        self.detectionEnabled = detectionEnabled

        self.handler = handler

        setupListener()
    }

    func setupListener() {
        if let listener = listener {
            notificationCenter.removeObserver(listener)
        }
        if detectionEnabled {
            listener = notificationCenter.addObserver(forName: .UIApplicationUserDidTakeScreenshot, object: nil, queue: .main) { [weak self] _ in
                guard let strongSelf = self, strongSelf.detectionEnabled else {
                    return
                }
                strongSelf.requestPhotosAuthorization()
            }
        } else {
            listener = nil
        }
    }

    private func requestPhotosAuthorization() {
        PHPhotoLibrary.requestAuthorization { authorizationStatus in
            OperationQueue.main.addOperation {
                switch authorizationStatus {
                case .authorized:
                    self.photoLibrary.register(self)
                case .denied, .notDetermined, .restricted:
                    self.handler(.failure(.unauthorized(status: authorizationStatus)))
                }
            }
        }
    }

    fileprivate func findScreenshot() {
        guard let screenshot = PHAsset.fetchLastScreenshot() else {
            self.handler(.failure(.fetchFailure))
            return
        }
        let imageManager: PHImageManager = self.imageManager ?? .default()
        imageManager.requestImage(for: screenshot,
                                  targetSize: PHImageManagerMaximumSize,
                                  contentMode: .default,
                                  options: .highQualitySynchronousLocalOptions()
        ) { [weak self] image, _ in
            OperationQueue.main.addOperation {
                guard let strongSelf = self else {
                    return
                }
                guard let image = image else {
                    strongSelf.handler(.failure(.loadFailure))
                    return
                }

                strongSelf.handler(.success(image))
            }
        }
    }

}

private extension PHAsset {

    static func fetchLastScreenshot() -> PHAsset? {
        let options = PHFetchOptions()

        options.fetchLimit = 1
        options.includeAssetSourceTypes = [.typeUserLibrary]
        options.wantsIncrementalChangeDetails = false
        options.predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoScreenshot.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        return PHAsset.fetchAssets(with: .image, options: options).firstObject
    }
}

extension ScreenshotDetector: PHPhotoLibraryChangeObserver {

    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        photoLibrary.unregisterChangeObserver(self)
        findScreenshot()
    }
}

private extension PHImageRequestOptions {

    static func highQualitySynchronousLocalOptions() -> PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = false
        options.isSynchronous = true
        return options
    }
}
*/

/*public protocol LogCollector { // Make more generic feedback with protocol

    func retrieveLogs(includeCurrent: Bool = true, rangeDate: Range<Date>? = nil) -> [String]
}*/
