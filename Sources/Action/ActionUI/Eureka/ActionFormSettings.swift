//
//  ActionFormSettings.swift
//  QMobileUI
//
//  Created by Eric Marchand on 01/07/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import UIKit

import QMobileAPI

// MARK: settings

struct ActionFormSettings { // XXX use settings
    // forms
    static let alertIfOneField = true // use an alert if one field

    // ui
    var useSection = true // Use one section (if false one section by fields)
    var tableViewStyle: UITableView.Style = .grouped

    // text area
    var sectionForTextArea = true
    var textAreaExpand = true // when focus

    // errors
    var errorColor: UIColor = UIColor(named: "error") ?? ColorCompatibility.systemRed
    var errorColorInLabel = true
    var errorAsDetail = true // use detail label, else add a new row
}

extension ActionFormSettings: JSONDecodable {

    init?(json: JSON) {
        self.useSection = json["useSection"].bool ?? true
        self.tableViewStyle = (json["useSection"].stringValue == "plain") ? UITableView.Style.plain: UITableView.Style.grouped
        self.sectionForTextArea = json["sectionForTextArea"].bool ?? true
        self.textAreaExpand = json["sectionForTextArea"].bool ?? true
        self.errorAsDetail = json["errorAsDetail"].bool ?? true
        self.errorColorInLabel = json["errorColorInLabel"].bool ?? true
    }
}
