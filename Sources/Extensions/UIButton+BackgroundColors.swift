//
//  UIButton+BackgroundColors.swift
//  QMobileUI
//
//  Created by Eric Marchand on 23/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

private var xoAssociationKey: UInt8 = 0
extension UIButton {

    public var backgroundColors: [UInt: UIColor]! {
        get {
            var backgroundColors = objc_getAssociatedObject(self, &xoAssociationKey) as? [UInt: UIColor]
            if backgroundColors == nil { // XXX check multithread  safety
                backgroundColors = [:]
                self.backgroundColors = backgroundColors
            }
            return backgroundColors
        }
        set(newValue) {
            objc_setAssociatedObject(self, &xoAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }

    override open var isSelected: Bool {
        didSet {
            updateBackgroundColorForState(state)
        }
    }

    override open var isHighlighted: Bool {
        didSet {
            updateBackgroundColorForState(state)
        }
    }

    func setTransparency(_ alpha: NSNumber) {
        self.alpha = CGFloat(alpha.floatValue) / 100.0
    }

    func setBackgroundColor(_ color: UIColor, forState state: UIControl.State) {
        backgroundColors[state.rawValue] = color

        if state == .normal {
            updateBackgroundColorForState(state)
        }
    }

    private func updateBackgroundColorForState(_ state: UIControl.State) {
        if let backgroundcolor = backgroundColors[state.rawValue] {
            self.backgroundColor = backgroundcolor
        }
    }

}
