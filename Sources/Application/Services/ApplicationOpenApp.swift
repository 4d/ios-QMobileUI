//
//  ApplicationOpenApp.swift
//  QMobileUI
//
//  Created by Eric Marchand on 20/08/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

/// Open native app
/// https://developer.apple.com/library/archive/featuredarticles/iPhoneURLScheme_Reference/Introduction/Introduction.html
open class ApplicationOpenAppBeta: NSObject {

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

extension ApplicationOpenAppBeta {

    class ActionOpenTapGestureRecognizer: UITapGestureRecognizer {

        var text: String
        var kind: ApplicationOpenAppBeta.Kind

        init?(text: String, kind: ApplicationOpenAppBeta.Kind) {
            self.text = text
            self.kind = kind
            super.init(target: nil, action: nil)
            // XXX valide kind with text and return nil if not valid

            addTarget(self, action: #selector(self.tapURLFunction(_:)))
        }

        @objc func tapURLFunction(_ sender: UITapGestureRecognizer) {
            if sender is ActionOpenTapGestureRecognizer {
                ApplicationOpenAppBeta.open(kind: kind, string: text)
            }
        }
    }

    public static func openActionTagGesture(text: String, kind: ApplicationOpenAppBeta.Kind) -> UITapGestureRecognizer? {
        return ActionOpenTapGestureRecognizer(text: text, kind: kind)
    }
}

extension ApplicationOpenAppBeta {
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
            ApplicationOpenAppBeta.openMap(destination: address)
            self.window = nil
        })
        actions.append(UIAlertAction(title: "Open in Maps", style: .default) { _ in
            ApplicationOpenAppBeta.openMap(address: address)
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
            ApplicationOpenAppBeta.openPhone(phone: phone)
            self.window = nil
        })
        actions.append(UIAlertAction(title: "Message", style: .default) { _ in
            ApplicationOpenAppBeta.openSMS(phone: phone)
            self.window = nil
        })
        actions.append(UIAlertAction(title: "FaceTime", style: .default) { _ in
            ApplicationOpenAppBeta.openFaceTime(call: phone)
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

extension ApplicationOpenAppBeta {

    private class MenuActionOpenTapGestureRecognizer: ActionOpenTapGestureRecognizer {

        override init?(text: String, kind: ApplicationOpenAppBeta.Kind) {
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

    public static func openMenuActionTagGesture(text: String, kind: ApplicationOpenAppBeta.Kind) -> UITapGestureRecognizer? {
        return MenuActionOpenTapGestureRecognizer(text: text, kind: kind)
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

import QMobileDataStore
import QMobileDataSync
extension ApplicationOpenAppBeta {

     public static func open(tableName: String) {
        let storyboardName = "\(tableName)ListForm" // TODO maybe here make some translation between name in 4D and name autorized for swift and core data
        let storyboard = UIStoryboard(name: storyboardName, bundle: .main)

        guard let viewControllerToPresent = storyboard.instantiateInitialViewController() else {
            logger.warning("Failed to present form for table '\(tableName)'")
            return
        }
        guard let presenter = UIApplication.topViewController else {
            logger.warning("Failed to get top form to present table '\(tableName)' form")
            return
        }
        presenter.present(viewControllerToPresent, animated: true, completion: {
            logger.debug("table '\(tableName)' form presented")
        })
    }

     public static func open(tableName: String, primaryKeyValue: Any) {

        let storyboardName = "\(tableName)DetailsForm" // TODO maybe here make some translation between name in 4D and name autorized for swift and core data
        let storyboard = UIStoryboard(name: storyboardName, bundle: .main)
        guard let viewControllerToPresent = storyboard.instantiateInitialViewController() else {
            logger.warning("Failed to present form for table '\(tableName)'")
            return
        }

        let dataStore = ApplicationDataStore.instance.dataStore
        _ = dataStore.perform(.background, wait: false, blockName: "Presenting \(tableName) record") { (context) in

            guard let tableInfo = context.tableInfo(for: tableName) else {
                logger.warning("Failed to get table info of table \(tableName) to present form")
                return
            }

            //let predicate = tableInfo.api.predicate(for: primaryKeyValue)
            guard let predicate  = tableInfo.primaryKeyPredicate(value: primaryKeyValue) else {
                logger.warning("Failed to request by predicate the \(tableName) with id \(primaryKeyValue) to present table '\(tableName)' form")
                return
            }

            guard let relationDataSource: DataSource = RecordDataSource(tableInfo: tableInfo, predicate: predicate, dataStore: dataStore) else {
                logger.warning("Cannot get record attribute to make data source: \(primaryKeyValue) when presenting form \(tableName)")
                return
            }
            let entry = DataSourceEntry(dataSource: relationDataSource)
            entry.indexPath = IndexPath(item: 0, section: 0)

            DispatchQueue.main.async {
                guard let presenter = UIApplication.topViewController else {
                    logger.warning("Failed to get top form to present table '\(tableName)' form")
                    return
                }
                viewControllerToPresent.prepare(with: entry)

                presenter.present(viewControllerToPresent, animated: true, completion: {
                    logger.debug("table '\(tableName)' form presented")
                })
            }

        }
    }

     public static func open(tableName: String, record: Record) {
        let storyboardName = "\(tableName)DetailsForm" // TODO maybe here make some translation between name in 4D and name autorized for swift and core data
        let storyboard = UIStoryboard(name: storyboardName, bundle: .main)

        guard let viewControllerToPresent = storyboard.instantiateInitialViewController() else {
            logger.warning("Failed to present form for table '\(tableName)'")
            return
        }
        guard let presenter = UIApplication.topViewController else {
            logger.warning("Failed to get top form to present table '\(tableName)' form")
            return
        }
        guard let relationDataSource: DataSource = RecordDataSource(record: record.store) else {
            logger.warning("Cannot get record attribute to make data source: \(record) when presenting form \(tableName)")
            return
        }
        let entry = DataSourceEntry(dataSource: relationDataSource)
        entry.indexPath = IndexPath(item: 0, section: 0)
        viewControllerToPresent.prepare(with: entry)

        presenter.present(viewControllerToPresent, animated: true, completion: {
            logger.debug("table '\(tableName)' form presented")
        })

    }

}
