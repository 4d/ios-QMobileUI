//
//  UIStoryboard+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 23/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

public extension UIStoryboard {

    /// Get the main storyboard from main bundle. @see `UIMainStoryboardFile` key
    static var main: UIStoryboard {
        let bundle = Bundle.main
        guard let storyboardName = bundle.object(forInfoDictionaryKey: "UIMainStoryboardFile") as? String else {
            fatalError("No main storyboard set in your app. In Info.plist, UIMainStoryboardFile key")
        }
        return UIStoryboard(name: storyboardName, bundle: bundle)
    }

}

// MARK: - Storyboards
extension UIStoryboard {
    public func instantiateViewController<T: UIViewController>(ofType type: T.Type) -> T? where T: IdentifiableProtocol {
        let instance = type.init()
        if let identifier = instance.storyboardIdentifier {
            return self.instantiateViewController(withIdentifier: identifier) as? T
        }
        return nil
    }

}

/// Object which can be associated to a `Storyboard`.
public protocol Storyboard {
    /// Returne the storyboard.
    static var storyboard: UIStoryboard { get }
    /// The storynoard identifier.
    static var identifier: String { get }
}

extension Storyboard {
    public static var storyboard: UIStoryboard {
        return UIStoryboard(name: self.identifier, bundle: nil)
    }

    public static func instantiateNavigationViewController() -> UINavigationController? {
        return self.storyboard.instantiateInitialViewController() as? UINavigationController
    }
    public static func instantiateInitialViewController() -> UIViewController? {
        return self.storyboard.instantiateInitialViewController()
    }
}

extension Storyboard where Self: UIViewController {
    public static var identifier: String {
        return self.className
    }
    public static func instantiate() -> Self? {
        return self.storyboard.instantiateInitialViewController() as? Self
    }
}

// MARK: - ReusableKind
public enum ReusableKind: String, CustomStringConvertible {
    case tableViewCell
    case collectionViewCell

    public var description: String { return self.rawValue }
}

// MARK: - SegueKind
public enum SegueKind: String, CustomStringConvertible {
    case relationship
    case show
    case presentation
    case embed
    case unwind
    case push
    case modal
    case popover
    case replace
    case custom

    public var description: String { return self.rawValue }
}

// MARK: - IdentifiableProtocol
public protocol IdentifiableProtocol: Equatable {
    var storyboardIdentifier: String? { get }
}

// MARK: - SegueProtocol
public protocol SegueProtocol {
    var identifier: String? { get }
}

public func ==<T: SegueProtocol, U: SegueProtocol>(lhs: T, rhs: U) -> Bool {
    return lhs.identifier == rhs.identifier
}

public func ~=<T: SegueProtocol, U: SegueProtocol>(lhs: T, rhs: U) -> Bool {
    return lhs.identifier == rhs.identifier
}

public func ==<T: SegueProtocol>(lhs: T, rhs: String) -> Bool {
    return lhs.identifier == rhs
}

public func ~=<T: SegueProtocol>(lhs: T, rhs: String) -> Bool {
    return lhs.identifier == rhs
}

public func ==<T: SegueProtocol>(lhs: String, rhs: T) -> Bool {
    return lhs == rhs.identifier
}

public func ~=<T: SegueProtocol>(lhs: String, rhs: T) -> Bool {
    return lhs == rhs.identifier
}

// MARK: - ReusableViewProtocol
public protocol ReusableViewProtocol: IdentifiableProtocol {
    var viewType: UIView.Type? { get }
}

public func ==<T: ReusableViewProtocol, U: ReusableViewProtocol>(lhs: T, rhs: U) -> Bool {
    return lhs.storyboardIdentifier == rhs.storyboardIdentifier
}

// MARK: - Protocol Implementation
extension UIStoryboardSegue: SegueProtocol {
}

extension UICollectionReusableView: ReusableViewProtocol {
    public var viewType: UIView.Type? { return type(of: self) }
    public var storyboardIdentifier: String? { return self.reuseIdentifier }
}

extension UITableViewCell: ReusableViewProtocol {
    public var viewType: UIView.Type? { return type(of: self) }
    public var storyboardIdentifier: String? { return self.reuseIdentifier }
}

// MARK: - UIViewController extension
extension UIViewController {
    public func perform<T: SegueProtocol>(segue: T, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        performSegue(withIdentifier: identifier, sender: sender)
    }

    public func perform<T: SegueProtocol>(segue: T) {
        perform(segue: segue, sender: nil)
    }
}
// MARK: - UICollectionView
extension UICollectionView {

    public func dequeue<T: ReusableViewProtocol>(reusable: T, for: IndexPath) -> UICollectionViewCell? {
        if let identifier = reusable.storyboardIdentifier {
            return dequeueReusableCell(withReuseIdentifier: identifier, for: `for`)
        }
        return nil
    }

    public func register<T: ReusableViewProtocol>(reusable: T) {
        if let type = reusable.viewType, let identifier = reusable.storyboardIdentifier {
            register(type, forCellWithReuseIdentifier: identifier)
        }
    }

    public func dequeueReusableSupplementaryViewOfKind<T: ReusableViewProtocol>(elementKind: String, withReusable reusable: T, for: IndexPath) -> UICollectionReusableView? {
        if let identifier = reusable.storyboardIdentifier {
            return dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: identifier, for: `for`)
        }
        return nil
    }

    public func register<T: ReusableViewProtocol>(reusable: T, forSupplementaryViewOfKind elementKind: String) {
        if let type = reusable.viewType, let identifier = reusable.storyboardIdentifier {
            register(type, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: identifier)
        }
    }
}
// MARK: - UITableView
extension UITableView {

    public func dequeue<T: ReusableViewProtocol>(reusable: T, for: IndexPath) -> UITableViewCell? {
        if let identifier = reusable.storyboardIdentifier {
            return dequeueReusableCell(withIdentifier: identifier, for: `for`)
        }
        return nil
    }

    public func register<T: ReusableViewProtocol>(reusable: T) {
        if let type = reusable.viewType, let identifier = reusable.storyboardIdentifier {
            register(type, forCellReuseIdentifier: identifier)
        }
    }

    public func dequeueReusableHeaderFooter<T: ReusableViewProtocol>(_ reusable: T) -> UITableViewHeaderFooterView? {
        if let identifier = reusable.storyboardIdentifier {
            return dequeueReusableHeaderFooterView(withIdentifier: identifier)
        }
        return nil
    }

    public func registerReusableHeaderFooter<T: ReusableViewProtocol>(_ reusable: T) {
        if let type = reusable.viewType, let identifier = reusable.storyboardIdentifier {
            register(type, forHeaderFooterViewReuseIdentifier: identifier)
        }
    }
}
