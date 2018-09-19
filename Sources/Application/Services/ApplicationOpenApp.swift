//
//  ApplicationOpenApp.swift
//  QMobileUI
//
//  Created by Eric Marchand on 20/08/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation

open class ApplicationOpenAppBeta {

    open static func openSafari(url: String) {
        self.openURL(url.trimmed)
    }

    open static func openMap(query: String) {
        self.openURL("http://maps.apple.com/?q=\(query.trimmed)")
    }

    open static func openMap(address: String) {
        self.openURL("http://maps.apple.com/?address=\(address)")
    }

    open static func openMap(location: String) {
        self.openURL("http://maps.apple.com/?ll=\(location)")
    }

    open static func openPhone(phone number: String) {
        self.openURL("tel:\(number.noSpace)")
    }

    open static func openSMS(phone number: String) {
        self.openURL("sms:\(number.noSpace)")
    }

    open static func openFaceTime(call: String) {
        self.openURL("facetime://\(call)")
    }

    open static func openFaceTimeAudio(call: String) {
        self.openURL("facetime-audio://\(call)")
    }

    open static func openMail(mailto: String) {
        self.openURL("mailto:\(mailto.trimmed)")
    }

    open static func openMail(mailto: String, subject: String, body: String) {
        self.openURL("mailto:\(mailto.trimmed)?subject=\(subject)&body=\(body)")
    }

    open static func openiBooks(isbn: String) {
        self.openURL("itms-bookss://itunes.apple.com/book/isbn\(isbn.trimmed)")
    }

    open static func openiBooks(bookid: String) {
        self.openURL("itms-bookss://itunes.apple.com/book/id\(bookid.trimmed)")
    }

    open static func openAppStore(appid: String) {
        self.openURL("itms-apps://itunes.apple.com/app/pages/id\(appid.trimmed)")
    }

    open static func openPhotoLibary() {
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
}
