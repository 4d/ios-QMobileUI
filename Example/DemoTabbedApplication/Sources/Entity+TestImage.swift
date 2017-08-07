//
//  Entity+TestImage.swift
//  DemoTabbedApplication
//
//  Created by Eric Marchand on 23/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

extension Entity {

    dynamic public var urlString: String {
        let imageNumber = integer % 1000
        return "https://unsplash.it/128?image=\(imageNumber)" // http://placehold.it/120x120&text=\(integer)"
    }

    dynamic public var url: URL {
        return URL(string: self.urlString)!
    }

    dynamic public var boolString: String {
        return String(bool)
    }

}

/*
 @NSManaged public var alpha: String?
 @NSManaged public var blob: NSData?
 @NSManaged public var bool: Bool
 @NSManaged public var category: String?
 @NSManaged public var date: TimeInterval
 @NSManaged public var float: Float
 @NSManaged public var iD: Int32
 @NSManaged public var image: NSObject?
 @NSManaged public var integer: Int16
 @NSManaged public var integer64: Int64
 @NSManaged public var longInteger: Int32
 @NSManaged public var object: NSObject?
 @NSManaged public var real: Double
 @NSManaged public var text: String?
 @NSManaged public var time: Int64
 */
