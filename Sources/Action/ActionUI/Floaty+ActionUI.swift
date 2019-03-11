//
//  Floaty+Action.swift
//  ActionBuilder
//
//  Created by Eric Marchand on 05/03/2019.
//  Copyright © 2019 phimage. All rights reserved.
//

import Foundation
/*
import Floaty

extension FloatyItem: ActionUI {
    public static func build(from action: Action, handler: @escaping ActionUI.Handler) -> ActionUI {
        let item = FloatyItem()
        item.title = action.label
        item.icon = ActionUIBuilder.actionImage(for: action)
        item.handler = { item in
            handler(action, item)
        }
        return item
    }
}

extension Floaty: ActionSheetUI {

    // public typealias ActionUIItem = FloatyItem
    public func actionUIType() -> ActionUI.Type {
        return FloatyItem.self
    }

    public func addActionUI(_ item: ActionUI?) {
        if let item = item as? FloatyItem {
            self.addItem(item: item)
        }
    }

}

extension Floaty {
    static func build(from actionSheet: ActionSheet, handler: @escaping ActionUI.Handler) -> Floaty {
        let manager = Floaty.global
        let floaty = manager.button
        floaty.items.removeAll()

        let items = floaty.build(from: actionSheet, handler: handler).compactMap { $0 as? FloatyItem}
        for item in items {
            floaty.addItem(item: item)
        }
        return floaty
    }
}
*/
