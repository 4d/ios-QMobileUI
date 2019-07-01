//
//  RowInitializable.swift
//  QMobileUI
//
//  Created by Eric Marchand on 01/07/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation

import Eureka

/// Protocol for row which must be initialized with a defaut value.
protocol RowInitializable {
    /// Set an init value.
    func rowInitialize()
}

extension DateRow {
    /// Set current date.
    func rowInitialize() {
        self.value = Date()
    }
}

extension _TimeIntervalFieldRow {
    func rowInitialize() {
        self.value = 0
    }
}

extension CheckRow {
    func rowInitialize() {
        self.value = false
    }
}

extension SwitchRow {
    func rowInitialize() {
        self.value = false
    }
}

extension StepperRow {
    func rowInitialize() {
        self.value = self.cell?.stepper?.minimumValue ?? 0.0
    }
}

extension SliderRow {
    func rowInitialize() {
        self.value = self.cell?.slider?.minimumValue ?? 0.0
    }
}
