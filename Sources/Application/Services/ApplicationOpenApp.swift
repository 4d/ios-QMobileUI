//
//  ApplicationOpenApp.swift
//  QMobileUI
//
//  Created by Eric Marchand on 20/08/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation

/// Open native app
/// https://developer.apple.com/library/archive/featuredarticles/iPhoneURLScheme_Reference/Introduction/Introduction.html
open class ApplicationOpenAppBeta: NSObject {

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
            ApplicationOpenAppBeta.openSafari(url: string)
        case .map:
            ApplicationOpenAppBeta.openMap(address: string)
        case .phone:
            ApplicationOpenAppBeta.openPhone(phone: string)
        case .sms:
            ApplicationOpenAppBeta.openSMS(phone: string)
        case .faceTime:
            ApplicationOpenAppBeta.openFaceTime(call: string)
        case .faceTimeAudio:
            ApplicationOpenAppBeta.openFaceTimeAudio(call: string)
        case .mail:
            ApplicationOpenAppBeta.openMail(mailto: string)
        }
    }

    public static func openSafari(url: String) {
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

extension ApplicationOpenAppBeta {

    fileprivate static func controller(_ title: String, _ message: String, _ actions: [UIAlertAction]) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
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

    public static func alertAddress(_ address: String) {
        var actions: [UIAlertAction] = []

        actions.append(UIAlertAction(title: "Get Directions", style: .default) { _ in
            ApplicationOpenAppBeta.openMap(destination: address)
        })
        actions.append(UIAlertAction(title: "Open in Maps", style: .default) { _ in
            ApplicationOpenAppBeta.openMap(address: address)
        })
        /*actions.append(UIAlertAction(title: "Add to Contacts", style: .default) { _ in

        })*/
        actions.append(UIAlertAction(title: "Copy Address", style: .default) { _ in
            UIPasteboard.general.string = address
        })
        actions.append(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        let title = address
        let message = ""

        controller(title, message, actions).presentOnTop()
    }

    public static func alertPhone(_ phone: String) {
        var actions: [UIAlertAction] = []

        actions.append(UIAlertAction(title: "Call", style: .default) { _ in
            ApplicationOpenAppBeta.openPhone(phone: phone)
        })
        actions.append(UIAlertAction(title: "Message", style: .default) { _ in
            ApplicationOpenAppBeta.openSMS(phone: phone)
        })
        actions.append(UIAlertAction(title: "FaceTime", style: .default) { _ in
            ApplicationOpenAppBeta.openFaceTime(call: phone)
        })
        actions.append(UIAlertAction(title: "Copy Phone Number", style: .default) { _ in
            UIPasteboard.general.string = phone
        })
        /*actions.append(UIAlertAction(title: "Add to Existing Contact", style: .default) { _ in

         })*/
        /*actions.append(UIAlertAction(title: "Create New contact", style: .default) { _ in

         })*/
        actions.append(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        let title = ""
        let message = phone

        controller(title, message, actions).presentOnTop()
    }

}

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
