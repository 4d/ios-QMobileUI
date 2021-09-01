//
//  UITableViewCell+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 31/08/2021.
//  Copyright © 2021 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

extension UITableViewCell {

    fileprivate var cellActionButtonLabel: [UILabel]? {
        superview?.subviews
            .filter { String(describing: $0).range(of: "UISwipeActionPullView") != nil }
            .flatMap { $0.subviews }
            .filter { String(describing: $0).range(of: "UISwipeActionStandardButton") != nil }
            .flatMap { $0.subviews }
            .compactMap { $0 as? UILabel }
    }

    fileprivate func adjustSwipeActionTextColors() {
        var previousBrightness: CGFloat = -1 // reference brightness for color
        cellActionButtonLabel?.forEach {
            if let color = $0.superview?.value(forKeyPath: "defaultBackgroundColor") as? UIColor {
                let currentBrightness = color.brightness
                if previousBrightness == -1 {
                    previousBrightness = currentBrightness
                }
                let isLight = currentBrightness > 0.5
                $0.textColor = isLight ? .black: .white
                $0.superview?.tintColor = isLight ? .black: .white

                let isPreviousLight = previousBrightness > 0.5
                if isPreviousLight != isLight { // we change color, but could we accept to not change?
                    if currentBrightness < 0.75 && currentBrightness > 0.25 {
                        $0.textColor = isPreviousLight ? .black: .white
                        $0.superview?.tintColor = isPreviousLight ? .black: .white
                    } // else we change color
                } else {
                    previousBrightness = currentBrightness
                }
            } else {
                logger.debug("⚠️ Cannot fix swipe action text color, internal apple api maybe change or just no color")
            }
        }
    }

    static func swizzle_adjustSwipeActionTextColors() {
        struct Once {
            static let once = Once()
            init() {
                swizzle(UITableViewCell.self, #selector(layoutSubviews), #selector(layoutSubviews_adjustSwipeActionTextColors))
                swizzle(UITableViewCell.self, #selector(layoutIfNeeded), #selector(layoutIfNeeded_adjustSwipeActionTextColors))
            }
        }
        _ = Once.once
    }

    @objc open func layoutSubviews_adjustSwipeActionTextColors() {
        adjustSwipeActionTextColors()
        layoutSubviews_adjustSwipeActionTextColors()
    }

    @objc open func layoutIfNeeded_adjustSwipeActionTextColors() {
        adjustSwipeActionTextColors()
        layoutIfNeeded_adjustSwipeActionTextColors()
    }

}

func swizzle(_ `class`: AnyClass, _ originalSelector: Selector, _ swizzledSelector: Selector) {
    let originalMethod = class_getInstanceMethod(`class`, originalSelector)!
    let swizzledMethod = class_getInstanceMethod(`class`, swizzledSelector)!

    let didAdd = class_addMethod(
        `class`, originalSelector,
        method_getImplementation(swizzledMethod),
        method_getTypeEncoding(swizzledMethod)
    )

    if didAdd {
        class_replaceMethod(
            `class`, swizzledSelector,
            method_getImplementation(originalMethod),
            method_getTypeEncoding(originalMethod)
        )
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}
