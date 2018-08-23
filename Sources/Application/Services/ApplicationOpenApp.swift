//
//  ApplicationOpenApp.swift
//  QMobileUI
//
//  Created by Eric Marchand on 20/08/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation

class ApplicationOpenApp {

    static func openSafari(url: String) {
        self.openURL(url)
    }

    static func openMap(query: String) {
        self.openURL("http://maps.apple.com/?q=\(query)")
    }

    static func openMap(address: String) {
        self.openURL("http://maps.apple.com/?address=\(address)")
    }

    static func openMap(location: String) {
        self.openURL("http://maps.apple.com/?ll=\(location)")
    }

    static func openPhone(phone number: String) {
        self.openURL("tel:\(number)")
    }

    static func openSMS(phone number: String) {
        self.openURL("sms:\(number)")
    }

    static func openFaceTime(call: String) {
        self.openURL("facetime://\(call)")
    }

    static func openFaceTimeAudio(call: String) {
        self.openURL("facetime-audio://\(call)")
    }

    static func openMail(mailto: String) {
        self.openURL("mailto:\(mailto)")
    }

    static func openMail(mailto: String, subject: String, body: String) {
        self.openURL("mailto:\(mailto)?subject=\(subject)&body=\(body)")
    }

    static func openiBooks(isbn: String) {
        self.openURL("itms-bookss://itunes.apple.com/book/isbn\(isbn)")
    }

    static func openiBooks(bookid: String) {
        self.openURL("itms-bookss://itunes.apple.com/book/id\(bookid)")
    }

    static func openAppStore(appid: String) {
        self.openURL("itms-apps://itunes.apple.com/app/pages/id\(appid)")
    }

    static func openPhotoLibary() {
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
