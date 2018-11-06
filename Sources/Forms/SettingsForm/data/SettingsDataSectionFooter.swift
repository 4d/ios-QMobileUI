//
//  SettingsDataSectionFooter.swift
//  QMobileUI
//
//  Created by Eric Marchand on 16/05/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import UIKit
import IBAnimatable
import QMobileDataSync

/// Footer for manage date section.
open class SettingsDataSectionFooter: UITableViewHeaderFooterView, UINibable, ReusableView {

    /// The label to display a date.
    @IBOutlet weak open var reloadFooterLabel: UILabel!

    private var observers: [NSObjectProtocol] = []

    public final override func awakeFromNib() {
        super.awakeFromNib()

        #if !TARGET_INTERFACE_BUILDER
        installDateListener()
        #endif
    }

    private func installDateListener() {
        self.refresh(with: dataLastSync())
        let refresh: (Notification) -> Void = { [weak self] notification in
            self?.refresh(with: dataLastSync())
        }
        let center = NotificationCenter.default
        // swiftlint:disable:next discarded_notification_center_observer
        observers.append(center.addObserver(forName: .dataSyncSuccess, object: nil, queue: .main, using: refresh))
        // swiftlint:disable:next discarded_notification_center_observer
        observers.append(center.addObserver(forName: .dataSyncFailed, object: nil, queue: .main, using: refresh))
    }

    deinit {
        let center = NotificationCenter.default
        for observer in observers {
            center.removeObserver(observer)
        }
    }

    func refresh(with date: Date?) {
        foreground { [weak self] in
            if let date = date {
                let date = DateFormatter.shortDateAndTime.string(from: date)
                self?.reloadFooterLabel.text = "   Last update: " + date // LOCALIZE
            } else {
                self?.reloadFooterLabel.text = ""
            }
            self?.reloadInTableView()
        }
    }

}
