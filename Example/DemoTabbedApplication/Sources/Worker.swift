//
//  Worker.swift
//  ___PACKAGENAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___
//  ___COPYRIGHT___

import Foundation

func background(execute work: @escaping @convention(block) () -> Swift.Void) {
    DispatchQueue.background.async(execute: work)
}
func background(_ delay: TimeInterval, execute work: @escaping @convention(block) () -> Swift.Void) {
    DispatchQueue.background.after(delay, execute: work)
}

func userInitiated(execute work: @escaping @convention(block) () -> Swift.Void) {
    DispatchQueue.userInitiated.async(execute: work)
}

/// Execute code in User Interface block. enqueue the task.
func foreground(execute work: @escaping @convention(block) () -> Swift.Void) {
    DispatchQueue.main.async(execute: work)
}
func userInteractive(execute work: @escaping @convention(block) () -> Swift.Void) {
    DispatchQueue.userInteractive.async(execute: work)
}

/// Execute code in User Interface thread. If already in execute immediately
func onForeground(_ closure: @escaping () -> Void) {
    if Thread.isMainThread {
        closure()
    } else {
        DispatchQueue.main.async {
            closure()
        }
    }
}
