//
//  ActionResultHandler.swift
//  QMobileUI
//
//  Created by phimage on 22/01/2021.
//  Copyright © 2021 Eric Marchand. All rights reserved.
//

import Foundation
import QMobileAPI

/// Handle an action results.
public protocol ActionResultHandler {
    typealias Block = (ActionResult, Action, ActionUI, ActionContext) -> Bool
    func handle(result: ActionResult, for action: Action, from: ActionUI, in context: ActionContext) -> Bool
}

/// Handle action result with a block
public struct ActionResultHandlerBlock: ActionResultHandler {
    var block: ActionResultHandler.Block
    public init(_ block: @escaping ActionResultHandler.Block) {
        self.block = block
    }
    public func handle(result: ActionResult, for action: Action, from actionUI: ActionUI, in context: ActionContext) -> Bool {
        return block(result, action, actionUI, context)
    }
}
