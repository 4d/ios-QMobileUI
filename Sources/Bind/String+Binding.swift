//
//  String+Binding.swift
//  QMobileUI
//
//  Created by Eric Marchand on 04/09/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation

extension Bundle {
    /// Bundle used to get binded localized value, default .main bundle of your application
    @nonobjc public static var uiBinding: Bundle = .main
}

extension String {

    /// File name where to find localizedBinding. Default 'Formatters'.
    @nonobjc public static var localizedBindingTableName: String = "Formatters"

    /// Localized string for binding
    var localizedBinding: String {
        return NSLocalizedString(self, tableName: String.localizedBindingTableName, bundle: .uiBinding, comment: "")
    }

    /// Loocalized string found in this framework
    var localizedFramework: String {
        return NSLocalizedString(self, bundle: Bundle(for: Binder.self), comment: "")
    }

    func localized(with comment: String = "", bundle: Bundle = Bundle(for: Binder.self)) -> String {
        return NSLocalizedString(self, bundle: bundle, comment: comment)
    }
}
