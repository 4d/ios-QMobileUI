//
//  Form.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/12/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation

public protocol Form {

    /// Called after the view has been loaded. Default does nothing
    func onLoad()
    /// Called when the view is about to made visible. Default does nothing
    func onWillAppear(_ animated: Bool)
    /// Called when the view has been fully transitioned onto the screen. Default does nothing
    func onDidAppear(_ animated: Bool)
    /// Called when the view is dismissed, covered or otherwise hidden. Default does nothing
    func onWillDisappear(_ animated: Bool)
    /// Called after the view was dismissed, covered or otherwise hidden. Default does nothing
    func onDidDisappear(_ animated: Bool)

}
