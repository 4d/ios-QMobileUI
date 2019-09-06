//
//  UIStoryboardSegue+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 02/09/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import UIKit

extension UIStoryboardSegue {

    func fix() {
        #if swift(>=5.1)
        if #available(iOS 13.0, *) {
            if Prephirences.Ui.Presentation.fullScreen {
                if destination.modalPresentationStyle == .automatic || destination.modalPresentationStyle == .pageSheet { // iOS13 default pageSheet could failed
                    destination.modalPresentationStyle = .fullScreen
                    logger.debug("\(self) has been presented using modal fullScreen style instead of \(destination.modalPresentationStyle)")
                } else {
                    logger.debug("\(self) is presented using modal style \(destination.modalPresentationStyle)")
                }
            } else {
                logger.debug("Segue fix is not installed. See setting")
            }
        }
        #else
        logger.debug("Segue fix is not installed. Not available with swift 5. Need 5.1")
        #endif
    }
}

import Prephirences
extension Prephirences {
    public struct Ui: Prephirencable { // swiftlint:disable:this type_name
        public struct Presentation: Prephirencable { // swiftlint:disable:this nesting
            static let parent = Ui.instance
            public static let fullScreen: Bool = instance["fullScreen"] as? Bool ?? false
        }
    }
}

#if DEBUG
extension UIViewController {
    // /!\ This method use private information
    fileprivate func canPerformSegue(withIdentifier identifier: String) -> Bool {
        guard let segues = self.value(forKey: "storyboardSegueTemplates") as? [NSObject] else { return false }
        return segues.first { $0.value(forKey: "identifier") as? String == identifier } != nil
    }
}
#endif
