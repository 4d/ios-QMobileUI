//
//  UISwipeGestureRecognizerDirection+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 12/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

// A temp file allow fast cocoapod developement allowing to inject code in dev pods when new files must be created

extension UISwipeGestureRecognizer.Direction: Hashable {
    public var hashValue: Int {
        return Int(self.rawValue)
    }

    public static let allArray: [UISwipeGestureRecognizer.Direction] = [.left, .right, .up, .down]

}

extension UIGestureRecognizer {

    open func addTarget(_ view: UIView, closure: @escaping (Cancellable) -> Void) -> Cancellable {
        return UIGestureRecognizerWithClosure(view, self, closure)
    }

}

import Moya

class UIGestureRecognizerWithClosure: NSObject, Cancellable {

    var closure: (Cancellable) -> Void
    weak var view: UIView?
    weak var recognizer: UIGestureRecognizer?

    init(_ view: UIView, _ recognizer: UIGestureRecognizer, _ closure: @escaping (Cancellable) -> Void) {
        self.closure = closure
        self.view = view
        self.recognizer = recognizer
        super.init()
        view.addGestureRecognizer(recognizer)

        self.recognizer?.addTarget(self, action: #selector(UIGestureRecognizerWithClosure.invokeTarget))
    }

    @objc func invokeTarget(nizer: UIGestureRecognizer) {
        self.closure(self)
    }

    public func cancel() {
        self.recognizer?.removeTarget(self, action: #selector(UIGestureRecognizerWithClosure.invokeTarget))
        self.view = nil
        self.recognizer = nil
    }
    public var isCancelled: Bool {
        return self.view == nil
    }
}
