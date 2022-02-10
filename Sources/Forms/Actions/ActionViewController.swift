//
//  ActionViewController.swift
//  New project
//
//  Created by emarchand on 08/02/2022.
//  Copyright © 2022 My Company. All rights reserved.
//

import UIKit
import QMobileAPI

// TODO: Move to QMobileUI
open class ActionViewController: UIViewController {

    open override func viewDidLoad() {
        super.viewDidLoad()

    }

    open func performActionOrShowActionSheet(_ sender: Any) {
        guard let actionSheet = actionSheet else {
            return
        }
        if actionSheet.actions.count == 1, let action = actionSheet.actions.first {
            let context: ActionContext = ActionActionContext(action: action)
            ActionManager.instance.prepareAndExecuteAction(action, BackgroundActionUI.instance, context)
        } else {

          //  var menu = UIMenu.build(from: actionSheet, context: sender, moreActions: nil, handler: ActionManager.instance.prepareAndExecuteAction)

            showActionSheet(sender)
        }
    }
}

struct ActionActionContext: ActionContext {

    var action: QMobileAPI.Action

    func actionContextParameters() -> ActionParameters? {
        /*if case .table(let tableName) == action.scope  {
            return [ActionParametersKey.table: tableName]
        }
        assert(action.scope  == .global)*/
        return nil
    }

    /// Provide value for a field.
    func actionParameterValue(for field: String) -> Any? {
        return nil
    }
}
