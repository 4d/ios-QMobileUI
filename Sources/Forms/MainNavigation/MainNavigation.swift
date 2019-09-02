//
//  MainNavigation.swift
//  QMobileUI
//
//  Created by Eric Marchand on 28/11/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation

/// Private bootstrap class to be able to create one in project. Could not make it parent because could be tab bar, collection, table etc...
class MainNavigation: NSObject, Storyboardable {
    static var storyboardIdentifier: String {
        return self.className
    }
}
