//
//  UIView+Context.swift
//  QMobileUI
//
//  Created by Eric Marchand on 15/03/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

import QMobileAPI

// MARK: - ActionUIContext

extension UICollectionViewCell: ActionContextProvider {

    public func actionContext() -> ActionContext? {
        return self.bindTo.table
    }

}

extension UITableViewCell: ActionContextProvider {

    public func actionContext() -> ActionContext? {
        return self.bindTo.table
    }

}

extension UIView: ActionContext {

    private var innerContext: ActionContext? {
        if let context = self.bindTo.table {
            return context
        } /*else if let parentCellView = self.parentCellView as? UIView, let context = parentCellView.bindTo.table {
             parameters = context.actionParameters(action: action)
         }*/ else if let provider = self.findActionContextProvider(), let context = provider.actionContext() {
            return context
        }
        logger.verbose("inner context not found for view \(self)")
        return nil
    }

    // A view try to find action context according to the view hierarchy
    public func actionParameters(action: Action) -> ActionParameters? {
        return self.innerContext?.actionParameters(action: action)
    }

    public func actionParameterValue(for field: String) -> Any? {
        return self.innerContext?.actionParameterValue(for: field)
    }

    fileprivate func findActionContextProvider() -> ActionContextProvider? {
        // view hierarchical search if current view do not provide the context
        if let provider = self as? ActionContextProvider {
            return provider
        }

        // view hierarchy recursion
        if let provider = self.superview?.findActionContextProvider() {
            return provider
        }

        // specific case for table and collection view cell which break the view hierarchy
        if let provider = self.parentCellView?.parentView?.findActionContextProvider() { // XXX maybe do it only at first level to optimize
            return provider
        }

        // in final ressort, the current view controller
        if let viewController = self.owningViewController {
            if let provider = viewController as? ActionContextProvider {
                return provider
            } else if let navigationController = viewController as? UINavigationController {
                if let provider = navigationController.visibleViewController  as? ActionContextProvider { // XXX sometime form becore the visible one
                    return provider
                } else if let provider = navigationController.children.first as? ActionContextProvider {
                    return provider
                }
            }
        }

        return nil
    }
}
