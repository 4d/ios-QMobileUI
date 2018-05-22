//
//  SettingReloadCell.swift
//  QMobileUI
//
//  Created by Eric Marchand on 16/05/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import UIKit

import Moya

import QMobileAPI
import QMobileDataSync

open class SettingReloadCell: UITableViewCell {

    @IBOutlet open weak var reloadButton: UIButton!

    weak var listener: DataReloadListener?

    open override func awakeFromNib() {
        ServerStatusManager.instance.add(listener: self)
    }

}

extension SettingReloadCell: ServerStatusListener {

    public func onStatusChanged(status: ServerStatus) {
        onForeground {
            // Activate reload button if status is ok
            self.reloadButton.isEnabled = status.isSuccess
        }
    }

}

// MARK: action on dialog button press

extension SettingReloadCell: DialogFormDelegate {

    // if ok pressed
    public func onOK(dialog: DialogForm, sender: Any) {
        if let button = sender as? LoadingButton {
            button.startAnimation()
        }
        listener = DataReloadManager.instance.listen { _ in
            onForeground {
                if let button = sender as? LoadingButton {
                    button.stopAnimation()
                }
                dialog.dismiss(animated: true)
                ServerStatusManager.instance.checkStatus(0) // XXX do elsewhere (break using listener)
            }
        }
        DataReloadManager.instance.reload()
    }

    // if cancel pressed
    public func onCancel(dialog: DialogForm, sender: Any) {
        DataReloadManager.instance.cancel()
        onForeground {
            dialog.dismiss(animated: true) /// XXX maybe wait cancel
        }
    }

}
