import SwiftUI
import UIKit

extension View {

    public func inject<SomeView>(_ view: SomeView) -> some View where SomeView: View {
        return overlay(view.frame(width: 0, height: 0))
    }

    public func introspect<TargetView: UIView>(
        selector: @escaping (IntrospectionUIView) -> TargetView?,
        customize: @escaping (TargetView) -> Void
    ) -> some View {
        return inject(UIKitIntrospectionView(
            selector: selector,
            customize: customize
        ))
    }

    public func introspectTableView(customize: @escaping (UITableView) -> Void) -> some View {
        return introspect(selector: Introspection.ancestorOrSiblingContaining, customize: customize)
    }

    public func onPushToRefresh(customize: @escaping (UIRefreshControl) -> Void, refreshing: @escaping (UIRefreshControl) -> Void) -> some View {
        return self.introspectTableView { tableView in
            let action = UIAction(title: "Refresh",
                                  image: nil,
                                  identifier: UIAction.Identifier(rawValue: "Refresh"),
                                  discoverabilityTitle: nil,
                                  attributes: .empty,
                                  state: UIMenuElement.State.on) { action in
                refreshing(action.sender as! UIRefreshControl) // swiftlint:disable:this force_cast
            }
            let refreshControl = UIRefreshControl(frame: CGRect(x: 0, y: 0, width: 100, height: 50), primaryAction: action)
            tableView.refreshControl = refreshControl
            customize(refreshControl)
        }
    }
}

public class IntrospectionUIView: UIView {

    required init() {
        super.init(frame: .zero)
        isHidden = true
        isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public struct UIKitIntrospectionView<TargetViewType: UIView>: UIViewRepresentable {

    let selector: (IntrospectionUIView) -> TargetViewType?
    let customize: (TargetViewType) -> Void

    public init(
        selector: @escaping (IntrospectionUIView) -> TargetViewType?,
        customize: @escaping (TargetViewType) -> Void
    ) {
        self.selector = selector
        self.customize = customize
    }

    public func makeUIView(context: UIViewRepresentableContext<UIKitIntrospectionView>) -> IntrospectionUIView {
        let view = IntrospectionUIView()
        view.accessibilityLabel = "UIView<\(TargetViewType.self)>"
        return view
    }

    public func updateUIView(_ uiView: IntrospectionUIView, context: UIViewRepresentableContext<UIKitIntrospectionView>) {
        DispatchQueue.main.async {
            guard let targetView = self.selector(uiView) else {
                return
            }
            self.customize(targetView)
        }
    }
}

private enum Introspection {

    static func siblingContaining<TargetView: UIView>(from entry: UIView) -> TargetView? {
        guard let viewHost = findViewHost(from: entry) else {
            return nil
        }
        return Introspection.previousSibling(containing: TargetView.self, from: viewHost)
    }

    static func siblingOfType<TargetView: UIView>(from entry: UIView) -> TargetView? {
        guard let viewHost = findViewHost(from: entry) else {
            return nil
        }
        return previousSibling(ofType: TargetView.self, from: viewHost)
    }

    static func ancestorOrSiblingContaining<TargetView: UIView>(from entry: UIView) -> TargetView? {
        if let tableView = findAncestor(ofType: TargetView.self, from: entry) {
            return tableView
        }
        return siblingContaining(from: entry)
    }

    static func ancestorOrSiblingOfType<TargetView: UIView>(from entry: UIView) -> TargetView? {
        if let tableView = findAncestor(ofType: TargetView.self, from: entry) {
            return tableView
        }
        return siblingOfType(from: entry)
    }

    static func findChild<AnyViewType: UIView>(ofType type: AnyViewType.Type, in root: UIView) -> AnyViewType? {
        for subview in root.subviews {
            if let typed = subview as? AnyViewType {
                return typed
            } else if let typed = findChild(ofType: type, in: subview) {
                return typed
            }
        }
        return nil
    }

    static func findChild<C: UIViewController>(ofType type: C.Type, in root: UIViewController) -> C? {
        for child in root.children {
            if let typed = child as? C {
                return typed
            } else if let typed = findChild(ofType: type, in: child) {
                return typed
            }
        }
        return nil
    }

    static func previousSibling<AnyViewType: UIView>(containing type: AnyViewType.Type, from entry: UIView) -> AnyViewType? {

        guard let superview = entry.superview,
            let entryIndex = superview.subviews.firstIndex(of: entry),
            entryIndex > 0
        else {
            return nil
        }

        for subview in superview.subviews[0..<entryIndex].reversed() {
            if let typed = findChild(ofType: type, in: subview) {
                return typed
            }
        }

        return nil
    }

    static func previousSibling<AnyViewType: UIView>(ofType type: AnyViewType.Type, from entry: UIView) -> AnyViewType? {

        guard let superview = entry.superview,
            let entryIndex = superview.subviews.firstIndex(of: entry),
            entryIndex > 0
        else {
            return nil
        }

        for subview in superview.subviews[0..<entryIndex].reversed() {
            if let typed = subview as? AnyViewType {
                return typed
            }
        }

        return nil
    }

    static func previousSibling<C: UIViewController>(ofType type: C.Type, from entry: UIViewController) -> C? {

        guard let parent = entry.parent,
            let entryIndex = parent.children.firstIndex(of: entry),
            entryIndex > 0
        else {
            return nil
        }

        for child in parent.children[0..<entryIndex].reversed() {
            if let typed = child as? C {
                return typed
            }
        }

        return nil
    }

    static func findAncestor<AnyViewType: UIView>(ofType type: AnyViewType.Type, from entry: UIView) -> AnyViewType? {
        var superview = entry.superview
        while let view = superview {
            if let typed = view as? AnyViewType {
                return typed
            }
            superview = view.superview
        }
        return nil
    }

    static func findViewHost(from entry: UIView) -> UIView? {
        var superview = entry.superview
        while let view = superview {
            if NSStringFromClass(type(of: view)).contains("ViewHost") {
                return view
            }
            superview = view.superview
        }
        return nil
    }
}
