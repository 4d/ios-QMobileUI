//
//  UIScreen+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 23/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

public extension UIScreen {

    static var orientation: UIInterfaceOrientation {
        return UIApplication.shared.statusBarOrientation
    }

    static var size: CGSize {
        return UIScreen.main.bounds.size
    }

    static var width: CGFloat {
        return UIScreen.main.bounds.size.width
    }

    static var height: CGFloat {
        return UIScreen.main.bounds.size.height
    }

    static var screenStatusBarHeight: CGFloat {
        return UIApplication.shared.statusBarFrame.height
    }

    static var screenHeightWithoutStatusBar: CGFloat {
        return orientation.isPortrait ? UIScreen.main.bounds.size.height - screenStatusBarHeight :
            UIScreen.main.bounds.size.width - screenStatusBarHeight
    }

}
