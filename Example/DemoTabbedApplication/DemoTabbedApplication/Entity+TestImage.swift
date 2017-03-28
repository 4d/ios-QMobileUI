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
