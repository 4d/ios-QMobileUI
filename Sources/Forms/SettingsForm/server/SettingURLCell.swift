//
//  SettingsURLCell.swift
//  QMobileUI
//
//  Created by Eric Marchand on 16/05/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import UIKit
import Prephirences

/// Setting servier url cell in setting form.
open class SettingURLCell: UITableViewCell {

    /// The label which display the server url
    @IBOutlet open weak var serverURLLabel: UILabel!

    /*weak*/var listener: NSObjectProtocol?

    open override func awakeFromNib() {
        initFormData()
    }

    private func initFormData() {
        let urlString = URL.qmobileURL.absoluteString
        serverURLLabel.text = urlString

        listener = Prephirences.serverURLChanged { serverURL in
            self.serverURLLabel.text = serverURL
        }
    }

}
