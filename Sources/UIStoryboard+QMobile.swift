//
//  UIStoryboard+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 23/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

public extension UIStoryboard {

    public static var main: UIStoryboard {
        let bundle = Bundle.main
        guard let storyboardName = bundle.object(forInfoDictionaryKey: "UIMainStoryboardFile") as? String else {
            fatalError("No main storyboard set in your app. In Info.plist, UIMainStoryboardFile key")
        }
        return  UIStoryboard(name: storyboardName, bundle: bundle)
    }

}
