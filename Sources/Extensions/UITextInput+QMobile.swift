//
//  UITextInput+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 28/09/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

extension UITextInput {

    public var cursorPosition: Int? {
        get {
            if let selectedRange = self.selectedTextRange {
                let cursorPosition = self.offset(from: self.beginningOfDocument, to: selectedRange.start)
                return cursorPosition
            }
            return nil
        }
        set {
            if let newValue = newValue {
                if let newPosition = self.position(from: self.beginningOfDocument, offset: newValue) {
                    self.selectedTextRange = self.textRange(from: newPosition, to: newPosition)
                }
            } else {
                // remove
            }
        }
    }

}
