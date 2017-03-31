//
//  Temp.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
public extension UILabel {
    // CLEAN test for binding with formatting
    dynamic public var textBool: Bool {
        get {
            guard let text = self.text else {
                return false
            }
            return text == "yes"
        }
        set {
            text = newValue ? "yes": "no"
        }
    }
}

extension UIBarButtonItem {
    
    open var bindTo: Binder! {
        if let view = value(forKey: "view") as? UIView { // a button?
            /*if let rootView = view.rootView { // a bar?
              
                return rootView.bindTo
            }*/
            return view.bindTo
        }
        return nil
    }
    
    open override func value(forUndefinedKey key: String) -> Any? {
        return bindTo
    }
    
}


public extension String {
    
    public var firstLetter: String {
        guard let firstLetter = self.characters.first else {
            return ""
        }
        return String(firstLetter)
    }

}

public extension UIRefreshControl {
    dynamic public var title: String? {
        get {
            guard let attributedTitle = self.attributedTitle else {
                return nil
            }
            return attributedTitle.string
        }
        set {
            if let title = newValue {
                attributedTitle = NSAttributedString(string: title)
            } else {
                attributedTitle = nil
            }
        }
    }
}

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }

    func localized(with comment: String) -> String {
        return NSLocalizedString(self, comment: comment)
    }

    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let emailTest   = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: self)
    }

    var htmlToAttributedString: NSAttributedString {
        do {
            if let data = data(using: .utf8) {
                let string = try NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: String.Encoding.utf8], documentAttributes: nil)
                return string
            }
        } catch {
            // Ignore (bad practice)
        }
        return NSAttributedString(string: self)
    }
}



open class CircleLayout: UICollectionViewLayout {
    
    private var center: CGPoint!
    private var itemSize: CGSize!
    private var radius: CGFloat!
    private var numberOfItems: Int!
    
  open  override func prepare() {
        super.prepare()
        
        guard let collectionView = collectionView else { return }
        
        center = CGPoint(x: collectionView.bounds.midX, y: collectionView.bounds.midY)
        let shortestAxisLength = min(collectionView.bounds.width, collectionView.bounds.height)
        itemSize = CGSize(width: shortestAxisLength * 0.1, height: shortestAxisLength * 0.1)
        radius = shortestAxisLength * 0.4
        numberOfItems = collectionView.numberOfItems(inSection: 0)
    }
    
   open override var collectionViewContentSize: CGSize {
        return collectionView!.bounds.size
    }
    
  open  override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        
        let angle = 2 * .pi * CGFloat(indexPath.item) / CGFloat(numberOfItems)
        
        attributes.center = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
        attributes.size = itemSize
        
        return attributes
    }
    
  open  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return (0 ..< collectionView!.numberOfItems(inSection: 0)).flatMap { item -> UICollectionViewLayoutAttributes? in
            self.layoutAttributesForItem(at: IndexPath(item: item, section: 0))
        }
    }
    
    // MARK: - Handle insertion and deletion animation
    
    private var inserted: [IndexPath]?
    private var deleted: [IndexPath]?
    
   open override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)
        
        inserted = updateItems
            .filter { $0.updateAction == .insert }
            .flatMap { $0.indexPathAfterUpdate }
        deleted = updateItems
            .filter { $0.updateAction == .delete }
            .flatMap { $0.indexPathBeforeUpdate }
    }
    
   open  override func finalizeCollectionViewUpdates() {
       super.finalizeCollectionViewUpdates()
        
        inserted = nil
        deleted = nil
    }
    
   open override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        var attributes = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath)
        guard inserted!.contains(itemIndexPath) else { return attributes }
        
        attributes = layoutAttributesForItem(at: itemIndexPath)
        attributes?.center = CGPoint(x: collectionView!.bounds.midX, y: collectionView!.bounds.midY)
        attributes?.alpha = 0
        return attributes
    }
    
   open  override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        var attributes = super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath)
        guard deleted!.contains(itemIndexPath) else { return attributes }
        
        attributes = layoutAttributesForItem(at: itemIndexPath)
        attributes?.center = CGPoint(x: collectionView!.bounds.midX, y: collectionView!.bounds.midY)
        attributes?.transform = CGAffineTransform.init(scaleX: 0.01, y: 0.01)
        return attributes
    }

}
open class CoverFlowLayout: UICollectionViewFlowLayout {

   open override func prepare() {
        self.scrollDirection = .horizontal
    }

   open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

   open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)!

        var visibleRect = CGRect()
        visibleRect.origin = self.collectionView!.contentOffset
        visibleRect.size = self.collectionView!.bounds.size

        let halfViewSize = visibleRect.width/2.0

        for layoutAttributes in attributes {
            let distance = visibleRect.midX - layoutAttributes.center.x
            let normalizedDistance = distance / halfViewSize

            if (abs(distance) < halfViewSize) {
                let zoom = 1 + 0.3*(1 - abs(normalizedDistance))
                let rotationTransform = CATransform3DMakeRotation(normalizedDistance * (CGFloat.pi / 2) * 0.8, 0, 0.2, 0)

                let zoomTransform = CATransform3DMakeScale(zoom, zoom, 1.0)
                layoutAttributes.transform3D = CATransform3DConcat(zoomTransform, rotationTransform)
                layoutAttributes.zIndex = Int(abs(normalizedDistance) * 10.0)

                var alpha = (1 - abs(normalizedDistance)) + 0.05
                if (alpha > 1.0) {
                    alpha = 1.0
                }
                layoutAttributes.alpha = alpha
            } else {
                layoutAttributes.alpha = 0.0
            }
        }

        return attributes
    }
}



open class QApplication: UIApplication {
    
    // MARK: singleton
    open override class var shared: QApplication {
        // swiftlint:disable force_cast
        return UIApplication.shared as! QApplication
    }

    // MARK: override
    open override func sendAction(_ action: Selector, to target: Any?, from sender: Any?, for event: UIEvent?) -> Bool {
        let done = super.sendAction(action, to: target, from: sender, for: event)

        return done
    }
}


extension URL {
    
    /// Allows optional argument when creating a URL
    public init?(string: String?) {
        guard let s = string else {
            return nil
        }
        self.init(string: s)
    }

    public func value(forQueryItem name: String) -> String? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false), let queryItems = components.queryItems else {
            return nil
        }
        return queryItems.filter({$0.name == name}).first?.value
    }
}

extension URLComponents {
    
    init?(string: String, parameters: [String: Any]?) {
        self.init(string: string)
        if let params = parameters {
            var queryItems = [URLQueryItem]()
            for param in params {
                queryItems.append(URLQueryItem(name: param.key, value: "\(param.value)"))
            }
            self.queryItems = queryItems
        }
    }
}


/// Transform a collection into a dictionary
/// From: https://gist.github.com/ijoshsmith/0c966b1752b9a5722e23
public extension Collection {
    
    func asDictionary<K, V>(transform:(_ element: Iterator.Element) -> [K : V]) -> [K : V] {
        var dictionary = [K : V]()
        self.forEach { element in
            for (key, value) in transform(element) {
                dictionary[key] = value
            }
        }
        return dictionary
    }
}

