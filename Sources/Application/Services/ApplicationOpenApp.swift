//
//  ApplicationOpenApp.swift
//  QMobileUI
//
//  Created by Eric Marchand on 20/08/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit
import Prephirences

/// Open native app
/// https://developer.apple.com/library/archive/featuredarticles/iPhoneURLScheme_Reference/Introduction/Introduction.html
open class ApplicationOpenApp: NSObject {
    
    /// setting: if no scheme when opening url, add http(s) scheme to URL. By default `https`, to change set value in setting for key `open.defaultURLScheme`.
    public static let preferedDefaultScheme: String = Prephirences.sharedInstance["open.defaultURLScheme"] as? String ?? "https"

    public static var window: UIWindow?

    public enum Kind {
        case safari
        case map
        case phone
        case sms
        case faceTime
        case faceTimeAudio
        case mail
    }

    public static func open(kind: Kind, string: String) {
        switch kind {
        case .safari:
            ApplicationOpenApp.openSafari(url: string)
        case .map:
            ApplicationOpenApp.openMap(address: string)
        case .phone:
            ApplicationOpenApp.openPhone(phone: string)
        case .sms:
            ApplicationOpenApp.openSMS(phone: string)
        case .faceTime:
            ApplicationOpenApp.openFaceTime(call: string)
        case .faceTimeAudio:
            ApplicationOpenApp.openFaceTimeAudio(call: string)
        case .mail:
            ApplicationOpenApp.openMail(mailto: string)
        }
    }

    public static func openSafari(url: String) {
        var url = url.trimmed
        if !url.contains(":/") {
            url = "\(preferedDefaultScheme)://\(url)"
        }
        self.openURL(url.trimmed)
    }

    public static func openMap(query: String) {
        self.openURL("http://maps.apple.com/?q=\(query.trimmed)")
    }

    public static func openMap(address: String) {
        self.openURL("http://maps.apple.com/?address=\(address.noNewLines.queryEncoded)")
    }

    public static func openMap(destination: String) {
        self.openURL("http://maps.apple.com/?daddr=\(destination.noNewLines.queryEncoded)")
    }

    public static func openMap(location: String) {
        self.openURL("http://maps.apple.com/?ll=\(location)")
    }

    public static func openPhone(phone number: String) {
        self.openURL("tel:\(number.noSpace)")
    }

    public static func openSMS(phone number: String) {
        self.openURL("sms:\(number.noSpace)")
    }

    public static func openFaceTime(call: String) {
        self.openURL("facetime://\(call)")
    }

    public static func openFaceTimeAudio(call: String) {
        self.openURL("facetime-audio://\(call)")
    }

    public static func openMail(mailto: String) {
        self.openURL("mailto:\(mailto.trimmed)")
    }

    public static func openMail(mailto: String, subject: String, body: String) {
        self.openURL("mailto:\(mailto.trimmed)?subject=\(subject)&body=\(body)")
    }

    public static func openiBooks(isbn: String) {
        self.openURL("itms-bookss://itunes.apple.com/book/isbn\(isbn.trimmed)")
    }

    public static func openiBooks(bookid: String) {
        self.openURL("itms-bookss://itunes.apple.com/book/id\(bookid.trimmed)")
    }

    public static func openAppStore(appid: String) {
        self.openURL("itms-apps://itunes.apple.com/app/pages/id\(appid.trimmed)")
    }

    public static func openPhotoLibary() {
        self.openURL("photos-redirect://")
    }

    /*static func openSetting() {
        self.openURL(UIApplicationOpenSettingsURLString)
    }*/

    static func openURL(_ string: String) {
        guard let url = URL(string: string) else {
            logger.warning("Could not encode url \(string)")
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { success in
                logger.warning("Open \(string) result: \(success)")
            }
        } else {
             logger.warning("Cannot open \(string). Please check if scheme is added to your Info.plist")
        }
    }

}

// MARK: String extension to format data for url
extension String {
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    var noSpace: String {
       return self.components(separatedBy: .whitespacesAndNewlines).joined()
    }
    var noNewLines: String {
        return self.components(separatedBy: .newlines).joined(separator: " ")
    }
    var queryEncoded: String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}

extension ApplicationOpenApp {

    class ActionOpenTapGestureRecognizer: UITapGestureRecognizer {

        var text: String
        var kind: ApplicationOpenApp.Kind

        init?(text: String, kind: ApplicationOpenApp.Kind) {
            self.text = text
            self.kind = kind
            super.init(target: nil, action: nil)
            // XXX valide kind with text and return nil if not valid

            addTarget(self, action: #selector(self.tapURLFunction(_:)))
        }

        @objc func tapURLFunction(_ sender: UITapGestureRecognizer) {
            if sender is ActionOpenTapGestureRecognizer {
                ApplicationOpenApp.open(kind: kind, string: text)
            }
        }
    }

    public static func openActionTagGesture(text: String, kind: ApplicationOpenApp.Kind) -> UITapGestureRecognizer? {
        return ActionOpenTapGestureRecognizer(text: text, kind: kind)
    }
}

extension ApplicationOpenApp {
	fileprivate static func controller(_ title: String, _ message: String, _ actions: [UIAlertAction], _ sender: Any) -> UIAlertController {
		let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet).checkPopUp(sender)

		// Add the action
		for action in actions {
			alertController.addAction(action)
        }

        // custom header view
       /* let margin: CGFloat = 10.0
        let rect = CGRect(x: margin, y: margin, width: alertController.view.bounds.size.width - margin * 4.0, height: 50)
        let customView = UIView(frame: rect)

        customView.backgroundColor = .green
        alertController.view.addSubview(customView)*/

        return alertController
    }

    public static func alertAddress(_ address: String, sender: Any) {
        var actions: [UIAlertAction] = []

        actions.append(UIAlertAction(title: "Get Directions", style: .default) { _ in
            ApplicationOpenApp.openMap(destination: address)
            self.window = nil
        })
        actions.append(UIAlertAction(title: "Open in Maps", style: .default) { _ in
            ApplicationOpenApp.openMap(address: address)
            self.window = nil
        })
        /*actions.append(UIAlertAction(title: "Add to Contacts", style: .default) { _ in

        })*/
        actions.append(UIAlertAction(title: "Copy Address", style: .default) { _ in
            UIPasteboard.general.string = address
            self.window = nil
        })
        actions.append(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.window = nil
        })
        let title = address
        let message = ""

        self.window = controller(title, message, actions, sender).presentOnTop()
    }

    public static func alertPhone(_ phone: String, sender: Any) {
        var actions: [UIAlertAction] = []

        actions.append(UIAlertAction(title: "Call", style: .default) { _ in
            ApplicationOpenApp.openPhone(phone: phone)
            self.window = nil
        })
        actions.append(UIAlertAction(title: "Message", style: .default) { _ in
            ApplicationOpenApp.openSMS(phone: phone)
            self.window = nil
        })
        actions.append(UIAlertAction(title: "FaceTime", style: .default) { _ in
            ApplicationOpenApp.openFaceTime(call: phone)
            self.window = nil
        })
        actions.append(UIAlertAction(title: "Copy Phone Number", style: .default) { _ in
            UIPasteboard.general.string = phone
            self.window = nil
        })
        /*actions.append(UIAlertAction(title: "Add to Existing Contact", style: .default) { _ in

         })*/
        /*actions.append(UIAlertAction(title: "Create New contact", style: .default) { _ in

         })*/
        actions.append(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.window = nil
        })

        let title = ""
        let message = phone

        self.window = controller(title, message, actions, sender).presentOnTop()
    }

}

extension ApplicationOpenApp {

    private class MenuActionOpenTapGestureRecognizer: ActionOpenTapGestureRecognizer {

        override init?(text: String, kind: ApplicationOpenApp.Kind) {
            super.init(text: text, kind: kind)
        }

        @objc override func tapURLFunction(_ sender: UITapGestureRecognizer) {
            if sender is MenuActionOpenTapGestureRecognizer {
                switch self.kind {
                case .phone:
                    alertPhone(self.text, sender: self)
                case .map:
                    alertAddress(self.text, sender: self)
                default:
                    super.tapURLFunction(sender)
                }
            }
        }
    }

    public static func openMenuActionTagGesture(text: String, kind: ApplicationOpenApp.Kind) -> UITapGestureRecognizer? {
        return MenuActionOpenTapGestureRecognizer(text: text, kind: kind)
    }
}

public typealias ApplicationOpenAppBeta = ApplicationOpenApp // for compatibility
/*
import Contacts
import ContactsUI
extension ApplicationOpenAppBeta: CNContactViewControllerDelegate {

    func addPhoneNumber(phone: String) {
        let store = CNContactStore()
        let contact = CNMutableContact()
        let homePhone = CNLabeledValue(label: CNLabelHome, value: CNPhoneNumber(stringValue: phone))
        contact.phoneNumbers = [homePhone]
        let controller = CNContactViewController(forUnknownContact: contact)
        controller.contactStore = store
        controller.delegate = self

        //navigationController.setNavigationBarHidden(false, animated: true)
        //navigationController.pushViewController(controller, animated: true)
    }

    public func contactViewController(_ viewController: CNContactViewController, shouldPerformDefaultActionFor property: CNContactProperty) -> Bool {
        return true
    }

    public func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {

    }

}
*/
