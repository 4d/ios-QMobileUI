//
//  ActionManager+ActionResultHandler.swift
//  QMobileUI
//
//  Created by phimage on 22/01/2021.
//  Copyright © 2021 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit
import QMobileAPI

extension ActionManager: ActionResultHandler {

    /// Handle action result after completion
    public func handle(result: ActionResult, for action: Action, from actionUI: ActionUI, in context: ActionContext) -> Bool {
        var handled = false
        for handler in handlers {
            handled = handler.handle(result: result, for: action, from: actionUI, in: context) || handled
        }
        return handled
    }

    /// Init  default handlers. Harcoded ones and possible custom one from
    /// `UIApplication` or one app service
    func setupDefaultHandler() {

        // Show debug log for each action result
        append { result, _, _, _ in
            logger.debug("Action result \(result.json)")
            return false // do not count if handled just for log
        }

        append(ActionResult.statusTextBlock)
        append(ActionResult.dataSynchroBlock)
        append(ActionResult.openURLBlock)
        append(ActionResult.pasteboardBlock)
        append(ActionResult.actionSheetBlock(self.prepareAndExecuteAction))
        append(ActionResult.actionBlock(self.prepareAndExecuteAction))
        append(ActionResult.deepLinkBlock)
        append(ActionResult.shareBlock)
        append(ActionResult.downloadURLBlock)

        onForeground {
            // Code to inject custom handlers.
            if let injectedHandler = UIApplication.shared.delegate as? ActionResultHandler {
                self.handlers.append(injectedHandler)
            }
            if let app = UIApplication.shared as? QApplication {
                for service in app.services.services {
                    if let injectedHandler = service as? ActionResultHandler {
                        self.handlers.append(injectedHandler)
                    }
                }
            }
        }
    }

    /// Append an handler using block
    public func append(_ block: @escaping ActionResultHandler.Block) {
        handlers.append(ActionResultHandlerBlock(block))
    }

    /// Append an handler
    public func append(_ handler: ActionResultHandler) {
        handlers.append(handler)
    }
}
