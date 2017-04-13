//
//  IBImageView.swift
//  
//
//  Created by Eric Marchand on 13/04/2017.
//
//

import Foundation


private var xoAssociationeKey: UInt8 = 0
@IBDesignable
class IBImageView: UIImageView {
    
    public var bindTest: IBLabelBinder! {
        get {
            var bindTo = objc_getAssociatedObject(self, &xoAssociationeKey) as? IBLabelBinder
            if bindTo == nil { // XXX check multithread  safety
                bindTo = IBLabelBinder(view: self)
                self.bindTest = bindTo
            }
            return bindTo
        }
        set(newValue) {
            objc_setAssociatedObject(self, &xoAssociationeKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
}


extension UIImageView {
    
    public var text: String {
        get {
            return ""
        }
        set {
            self.image = UIImage.image(from: newValue, size: self.frame.size)
        }
    }

}
