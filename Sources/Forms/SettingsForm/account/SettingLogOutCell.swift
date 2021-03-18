//
//  SettingLogOutCell.swift
//  QMobileUI
//
//  Created by Eric Marchand on 17/05/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import UIKit

import Moya

import QMobileAPI
import QMobileDataSync

open class SettingLogOutCell: UITableViewCell {

    @IBOutlet open weak var logOutButton: UIButton!

}

// MARK: action on dialog button press

extension SettingLogOutCell: DialogFormDelegate {

    // if ok pressed
    public func onOK(dialog: DialogForm, sender: Any) {
        if let button = sender as? LoadingButton {
            button.startAnimation()
        }

        ApplicationAuthenticate.instance.didLogout() // cancel any sync

        // call logout
        _ = APIManager.instance.logout { result in
            logger.info("Logout \(result)")

            foreground {
                if let button = sender as? LoadingButton {
                    button.stopAnimation()
                }
                dialog.dismiss(animated: true) {
                    self.performTransition(sender: sender)
                }
            }
        }
    }

    func performTransition(sender: Any? = nil) {
        foreground {
            if let viewController =  self.owningViewController {
                viewController.performSegue(withIdentifier: "logout", sender: sender)
            } else {
                logger.warning("Bug: cannot get controller to perform logout segue/transition")
            }
        }
    }

    // if cancel pressed
    public func onCancel(dialog: DialogForm, sender: Any) {
        onForeground {
            dialog.dismiss(animated: true)
        }
    }

}
