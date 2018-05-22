//
//  SettingsServerSectionFooter.swift
//  DemoTabbedApplication
//
//  Created by Eric Marchand on 06/09/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

import IBAnimatable

open class SettingsServerSectionFooter: UITableViewHeaderFooterView, UINibable, ReusableView {

    @IBOutlet weak open var iconView: AnimatableView!
    @IBOutlet weak open var iconAnimationView: ServerStatusView!
    @IBOutlet weak open var titleLabel: UILabel!
    @IBOutlet weak open var detailLabel: UILabel!

    // install tap gesture
    public final override func awakeFromNib() {
        super.awakeFromNib()

        #if !TARGET_INTERFACE_BUILDER
        self.installTagGesture()
        ServerStatusManager.instance.add(listener: self)
        #endif
        self.detailLabel.isHidden = true
    }

    // Install tap gesture on footer to relaunch server status check
    // Override it and do nothing remote it
    open func installTagGesture() {
        let gestureRecognizer =  UITapGestureRecognizer(target: nil, action: #selector(self.tapped(_:)))
        self.iconView.addGestureRecognizer(gestureRecognizer)
        self.iconView.isUserInteractionEnabled = true
        self.titleLabel.addGestureRecognizer(gestureRecognizer)
        self.titleLabel.isUserInteractionEnabled = true
    }

    @objc open func tapped(_ sender: UITapGestureRecognizer) {
        ServerStatusManager.instance.checkStatus(2)
    }

}

extension SettingsServerSectionFooter: ServerStatusListener {

    public func onStatusChanged(status: ServerStatus) {
        foreground { [weak self] in
            self?.iconView.backgroundColor = status.color
            self?.titleLabel.text = status.message
            self?.detailLabel.text = status.detailMessage
            if status.isChecking {
                self?.iconAnimationView.startAnimating()
            } else {
                self?.iconAnimationView.stopAnimating()
            }
            self?.reloadInTableView()
        }
    }
}

/// Indicator view for server status
open class ServerStatusView: AnimatableActivityIndicatorView {}
