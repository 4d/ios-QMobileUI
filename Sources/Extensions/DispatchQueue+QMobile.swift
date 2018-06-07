//
//  DispatchQueue.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

public extension DispatchQueue {

    public static var userInteractive: DispatchQueue { return DispatchQueue.global(qos: .userInteractive) }
    public static var userInitiated: DispatchQueue { return DispatchQueue.global(qos: .userInitiated) }
    public static var utility: DispatchQueue { return DispatchQueue.global(qos: .utility) }
    public static var background: DispatchQueue { return DispatchQueue.global(qos: .background) }

    public func after(_ delay: TimeInterval, execute closure: @escaping () -> Void) {
        asyncAfter(deadline: .now() + delay, execute: closure)
    }

}

public func background(execute work: @escaping @convention(block) () -> Swift.Void) {
    DispatchQueue.background.async(execute: work)
}
public func background(_ delay: TimeInterval, execute work: @escaping @convention(block) () -> Swift.Void) {
    DispatchQueue.background.after(delay, execute: work)
}

/// Execute code in User Interface queue, ie. the main queue.
public func foreground(execute work: @escaping @convention(block) () -> Swift.Void) {
    DispatchQueue.main.async(execute: work)
}
/// Execute code in User Interface thread. If already in execute immediately
public func onForeground(_ closure: @escaping () -> Void) {
    if Thread.isMainThread {
        closure()
    } else {
        DispatchQueue.main.async {
            closure()
        }
    }
}

public func userInitiated(execute work: @escaping @convention(block) () -> Swift.Void) {
    DispatchQueue.userInitiated.async(execute: work)
}

// could be replaced by a framework like Then
extension OperationQueue {
    public convenience init(underlyingQueue: DispatchQueue) {
        self.init()
        self.underlyingQueue = underlyingQueue
    }
    public convenience init(underlyingQueue: DispatchQueue, maxConcurrentOperationCount: Int) {
        self.init()
        self.underlyingQueue = underlyingQueue
        self.maxConcurrentOperationCount = maxConcurrentOperationCount
    }
}
