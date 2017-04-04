//
//  QApplication.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

// Root class of QMobile application
open class QApplication: UIApplication {

    // MARK: singleton
    open override class var shared: QApplication {
        // swiftlint:disable force_cast
        return UIApplication.shared as! QApplication
    }

    // MARK: override
    open override func sendAction(_ action: Selector, to target: Any?, from sender: Any?, for event: UIEvent?) -> Bool {
        let done = super.sendAction(action, to: target, from: sender, for: event)

        return done
    }

}
