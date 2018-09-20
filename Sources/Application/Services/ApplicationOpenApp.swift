//
//  ApplicationOpenApp.swift
//  QMobileUI
//
//  Created by Eric Marchand on 20/08/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation

open class ApplicationOpenAppBeta {

    public static func openSafari(url: String) {
        self.openURL(url.trimmed)
    }

    public static func openMap(query: String) {
        self.openURL("http://maps.apple.com/?q=\(query.trimmed)")
    }

    public static func openMap(address: String) {
        self.openURL("http://maps.apple.com/?address=\(address)")
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
}
