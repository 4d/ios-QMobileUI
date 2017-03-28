//
//  UIScreen+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 23/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

public extension UIScreen {

    public static var orientation: UIInterfaceOrientation {
        return UIApplication.shared.statusBarOrientation
    }

    public static var size: CGSize {
        return UIScreen.main.bounds.size
    }

    public static var width: CGFloat {
        return UIScreen.main.bounds.size.width
    }

    public static var height: CGFloat {
        return UIScreen.main.bounds.size.height
    }

    public static var screenStatusBarHeight: CGFloat {
        return UIApplication.shared.statusBarFrame.height
    }

    public static var screenHeightWithoutStatusBar: CGFloat {
        return UIInterfaceOrientationIsPortrait(orientation) ? UIScreen.main.bounds.size.height - screenStatusBarHeight :
            UIScreen.main.bounds.size.width - screenStatusBarHeight
    }

}
