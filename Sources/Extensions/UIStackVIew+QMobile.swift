//
//  UIStackVIew+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 20/08/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import UIKit

extension UIStackView {

    /// Configure intermediate stack view. By default `.horizontal` and `.fillEqually`
    public static let defaultRearrangeConfigure: ((UIStackView, Int) -> Void) = { configurableStackView, index in
        configurableStackView.alignment = .fill
        configurableStackView.distribution = .fillEqually
        configurableStackView.axis = .horizontal
        configurableStackView.autoresizesSubviews = true
    }

    /// Rearrange `subviews` by introducing intermediate `UIStackView`.
    /// ex: ``distribution: ( $0 % 2 = 0)` will arrange the subview in two columns.
    public func rearrange(distribution: (Int) -> Bool, configure: ((UIStackView, Int) -> Void) = UIStackView.defaultRearrangeConfigure) {
        let views  = self.arrangedSubviews

        for view in views {
            self.removeArrangedSubview(view)
        }

        var stackView: UIStackView?
        for index in 0..<views.count {
            let view = views[index]
            if distribution(index) {
                let configurableStackView = UIStackView()
                configure(configurableStackView, index)
                stackView = configurableStackView
                self.addArrangedSubview(configurableStackView)
            }
            if let configurableStackView = stackView {
                configurableStackView.addArrangedSubview(view)
            } else {
                self.addArrangedSubview(view)
            }
        }
    }

}
