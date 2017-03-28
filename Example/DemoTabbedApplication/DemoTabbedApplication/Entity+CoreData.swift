//
//  Entity+CoreData.swift
//  DemoTabbedApplication
//
//  Created by Eric Marchand on 20/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import CoreData

extension Entity {
    
    @NSManaged open var string: String
    
    @NSManaged open var bool: Bool
    
    @NSManaged open var category: String?

    @NSManaged open var integer: Int

    
    // table section not working with transient property ie. computed property, let user do it in 4d
    // http://stackoverflow.com/questions/15972040/keypath-transientproperty-not-found-in-entity
    /*dynamic open var category: String? {
        guard let firstLetter = self.string?.characters.first else {
            return ""
        }
        return String(firstLetter)
    }*/
    
    
}


