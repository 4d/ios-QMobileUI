//
//  Alert.swift
//  ___PACKAGENAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___
//  ___COPYRIGHT___

import Foundation
import QMobileUI

public func alert(title: String, error: Error) {
    QMobileUI.alert(title: title, error: error)
}

public func alert(title: String, message: String? = nil) {
    QMobileUI.alert(title: title, message: message)
}
