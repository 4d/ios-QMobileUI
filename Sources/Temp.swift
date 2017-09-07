//
//  Temp.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

// A temp file allow fast cocoapod developement allowing to inject code in dev pods when new files must be created

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
extension RawRepresentable where RawValue == Int {
    
    public var indexSet: IndexSet {
        return IndexSet(integer: rawValue)
    }
    
    public static func == (section: Self, value: Int) -> Bool {
        return section.rawValue == value
    }

}

extension UITableViewController {
    
    public func reload<S: RawRepresentable>(section: S) where S.RawValue == Int {
        assert(Thread.isMainThread)
        self.tableView.reloadSections(section.indexSet, with: .none)
    }
    
}
