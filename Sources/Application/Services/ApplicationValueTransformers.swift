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
            let name = trans.name.rawValue.replacingFirstOccurrence(of: StringTransformers.namePrefix, with: "")
            ValueTransformer.setValueTransformer(trans, for: name)
        }
        for trans in NumberTransformers.transformers {
            let name = trans.name.rawValue.replacingFirstOccurrence(of: NumberTransformers.namePrefix, with: "")
            ValueTransformer.setValueTransformer(trans, for: name)
        }

        let names = ValueTransformer.valueTransformerNames()
        logger.debug("There is \(names.count) ValueTransformer registered")
        logger.verbose("ValueTransformers: \(names.map {$0.rawValue}.joined(separator: ","))")
    }

}
fileprivate extension String {
    func replacingFirstOccurrence(of string: String, with replacement: String) -> String {
        guard let range = self.range(of: string) else { return self }
        return replacingCharacters(in: range, with: replacement)
    }
}

extension ApplicationValueTransformers: ApplicationService {

    static var instance: ApplicationService = ApplicationValueTransformers()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        loadValueTransformers()
    }

}

extension ValueTransformer {

    open class func setValueTransformer(_ transformer: ValueTransformerRegisterable, for name: String) {
        let transformer = transformer.transformer
        self.setValueTransformer(transformer, forName: NSValueTransformerName(name))
    }

}
