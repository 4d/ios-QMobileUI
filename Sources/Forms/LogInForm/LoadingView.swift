//
//  LoadingView.swift
//  New Project
//
//  Created by Eric Marchand on 30/11/2018.
//  Copyright © 2018 My Company. All rights reserved.
//

import UIKit
import SwiftMessages
import IBAnimatable

open class LoadingView: MessageView {
    @IBOutlet open weak var activityIndicator: AnimatableActivityIndicatorView!

    open override func awakeFromNib() {
        activityIndicator.startAnimating()
    }
}
