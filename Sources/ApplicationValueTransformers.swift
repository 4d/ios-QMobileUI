//
//  ApplicationTransformer..swift
//  Invoices
//
//  Created by Eric Marchand on 10/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

import ValueTransformerKit

class ApplicationValueTransformers: NSObject {

    func loadValueTransformers() {
        // Register uppercased, lowercased, capitalized, see StringTransformers
        for trans in StringTransformers.transformers {
            ValueTransformer.setValueTransformer(trans, for: trans.rawValue)
        }
        for trans in NumberTransformers.transformers {
            ValueTransformer.setValueTransformer(trans, for: trans.rawValue)
        }

        let names = ValueTransformer.valueTransformerNames()
        logger.debug("There is \(names.count) ValueTransformer registered")
        logger.verbose("ValueTransformers: \(names.map {$0.rawValue}.joined(separator: ","))")
    }

}

extension ApplicationValueTransformers: ApplicationService {

    static var instance: ApplicationService = ApplicationValueTransformers()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]?) {
        loadValueTransformers()
    }

}

extension ValueTransformer {

    open class func setValueTransformer(_ transformer: ValueTransformerRegisterable, for name: String) {
        let transformer = transformer.transformer
        self.setValueTransformer(transformer, forName: NSValueTransformerName(name))
    }

}
