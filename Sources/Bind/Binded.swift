//
//  Binded.swift
//  QMobileUI
//
//  Created by phimage on 26/03/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation

public protocol Binded: NSObjectProtocol {
	/// A Binded object must have a Binder.
	var bindTo: Binder { get }
	
	/// Return the real element which contain all information. A root one.
	var bindedRoot: Binded { get }
	
	// MARK: properties
	/// `true` if a property exist
	func hasProperty(name: String) -> Bool
	/// list of properties
	var propertyNames: [String] { get }
	/// set value for a property using its name
	func setProperty(name: String, value: Any?)
	/// get property value
	func getPropertyValue(name: String) -> Any?
}

extension Binded {
	public func hasProperty(name: String) -> Bool {
		for child in Mirror(reflecting: self).children where child.label == name {
			return true
		}
		return false
	}
	public var propertyNames: [String] {
		return Mirror(reflecting: self).children.compactMap { $0.label }
	}
}
