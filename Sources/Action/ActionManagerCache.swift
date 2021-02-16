//
//  ActionManagerCache.swift
//  QMobileUI
//
//  Created by emarchand on 16/02/2021.
//  Copyright © 2021 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

class ActionManagerCache {

    var memory: [String: UIImage] = [:]

    func store(cacheId: String, image: UIImage) {
        memory[cacheId] = image
    }

    func get(cacheId: String) -> UIImage? {
        return memory[cacheId]
    }

    func remove(cacheId: String) {
        memory.removeValue(forKey: cacheId)
    }
}
