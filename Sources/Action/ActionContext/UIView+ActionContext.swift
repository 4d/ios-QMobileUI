//
//  UIView+Context.swift
//  QMobileUI
//
//  Created by Eric Marchand on 15/03/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation

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

    public func actionParameters(action: Action) -> ActionParameters? {
        var parameters: ActionParameters?

        if let context = self.bindTo.table {
            parameters = context.actionParameters(action: action)
        } /*else if let parentCellView = self.parentCellView as? UIView, let context = parentCellView.bindTo.table {
            parameters = context.actionParameters(action: action)
        }*/ else if let provider = self.findActionContextProvider(action), let context = provider.actionContext() {
            parameters = context.actionParameters(action: action)
        }
        return parameters
    }

    fileprivate func findActionContextProvider(_ action: Action) -> ActionContextProvider? {
        // view hierarchical search if current view do not provide the context
        if let provider = self as? ActionContextProvider {
            return provider
        }

        // view hierarchy recursion
        if let provider = self.superview?.findActionContextProvider(action) {
            return provider
        }

        // specific case for table and collection view cell which break the view hierarchy
        if let provider = self.parentCellView?.parentView?.findActionContextProvider(action) { /// XXX maybe do it only at first level to optimize
            return provider
        }

        // in final ressort, the current view controller
        if let viewController = self.owningViewController {
            if let provider = viewController as? ActionContextProvider {
                return provider
            } else if let navigationController = viewController as? UINavigationController {
                if let provider = navigationController.visibleViewController  as? ActionContextProvider {
                    return provider
                }
            }
        }

        return nil
    }
}
