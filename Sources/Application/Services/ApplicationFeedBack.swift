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

import MessageUI

enum FeedbackEvent: String {
    case shake
   /* case screenshot
    case floatingButton
    case twoFindersSwipeLeft
    case rightEdgePan*/
    case none
}

class ApplicationFeedback: NSObject {

    var shakeListener: AnyObject?

}

extension ApplicationFeedback: ApplicationService {

    static var instance: ApplicationService = ApplicationFeedback()

    static var pref: PreferencesType {
        return ProxyPreferences(preferences: preferences, key: "feedback.")
    }

    // swiftlint:disable:next function_body_length
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
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
                self?.showDialog(tips: "💡 Shake the device to display this dialog again.")
            }
       /* case .screenshot:
            shakeListener = center.addObserver(forName: .UIApplicationUserDidTakeScreenshot, object: nil, queue: .main) { [weak self] _ in
             self?.showLogSendDialog()
             }*/
        case .none:
            logger.info("Feedback not activated")
        }

    }

    func applicationWillTerminate(_ application: UIApplication) {
        if let shakeListener = shakeListener {
            NotificationCenter.default.removeObserver(shakeListener)
        }
    }

    func showDialog(tips: String) { // tips must depend of parent event
        let alert = UIAlertController(title: "How can we help you?",
                                      message: tips,
                                      preferredStyle: .actionSheet)
        /*alert.addAction(UIAlertAction(title: "💬 Talk to us", style: .default, handler: { _ in
         self.mailCompose(subject: "Talk to us", body: "here sugest improvement")
         }))*/
        /*alert.addAction(UIAlertAction(title: "📣 Suggest an improvement", style: .default, handler: { _ in
            self.mailCompose(subject: "Suggest an improvement", body: "here sugest improvement")
        }))*/
        alert.addAction(UIAlertAction(title: "🐞 Report a problem", style: .destructive, handler: { _ in
            self.mailCompose(subject: "Problem report", body: "here describe your issue", attachLog: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        alert.presentOnTop()
    }

}

extension ApplicationFeedback: MFMailComposeViewControllerDelegate {

    func showSendMailErrorAlert(toRecipient: String) {
        let alert = UIAlertController(title: "Could Not Send Email",
                                      message: "Your device could not send e-mail directly.  Please check e-mail configuration and try again.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "📧 Open Mail app", style: .default, handler: { _ in
            if let url = URL(string: "mailto:\(toRecipient)") {
                UIApplication.shared.open(url)
            }
        }))
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))

        alert.presentOnTop()
    }

    func mailCompose(subject: String, body: String, isBodyHTML: Bool = false, attachLog: Bool = false, toRecipient: String = "eric.marchand@4d.com") {
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

        // mailComposerVC.setPreferredSendingEmailAddress(<#T##emailAddress: String##String#>)

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
            if let image = UIApplication.shared.keyWindow?.rootViewController?.view?.window?.screenshot() {
                if let data = UIImagePNGRepresentation(image) {
                    mailComposerVC.addAttachmentData(data, mimeType: "application/png", fileName: "screenshot.jpg")
                }
            }

            if zipPath.exists {
                try? zipPath.deleteFile()
            }
        }

        mailComposerVC.presentOnTop()
    }

    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        logger.info("Mail \(result)")
        if let error = error {
            logger.error("Mail: \(error)")
        }
    }
}

public extension UIWindow {

    func screenshot() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.frame.size, self.isOpaque, UIScreen.main.scale)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
