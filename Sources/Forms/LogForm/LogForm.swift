//
//  LogForm.swift
//  QMobileUI
//
//  Created by Eric Marchand on 17/07/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import UIKit
import FileKit
import XCGLogger

protocol LogFormDegate: NSObjectProtocol {
    func logFormDismiss(logForm: LogForm)
    func logFormSend(logForm: LogForm)
}

@IBDesignable
open class LogForm: UIViewController, Storyboardable {

    /// If colorize, change color of the text according to log level.
    /// Work only if use a `BasicLogDestionation` from XCGLogger.
    @IBInspectable open var colorize: Bool = true

    /// Text view used to display the logs.
    @IBOutlet weak var textView: UITextView!
    @IBOutlet var globalView: UIView!

    weak var delegate: LogFormDegate?

    /// Path of the file.
    open var path: Path?

    // MARK: - vc life

    override open func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.foreground]
        if let path = path {
            fill(with: path)
        }
        if self.traitCollection.userInterfaceStyle == .dark {
            globalView.backgroundColor = .black
        } else {
            globalView.backgroundColor = .white
        }
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        textView.scrollToTheEnd()
    }
    // MARK: - Fill

    fileprivate func fill(with logText: String?) {
        if colorize {
            let mutableAttr = NSMutableAttributedString()
            let lines = logText?.split(separator: "\n")
            for line in lines ?? [] {
                mutableAttr.append(NSAttributedString(string: String(line), attributes: colorsFromLevel[BaseDestination.level(for: String(line))] ?? [:]))
                mutableAttr.append(NSAttributedString(string: "\n"))
            }
            textView?.attributedText = mutableAttr
        } else {
            textView?.text = logText
        }
    }

    fileprivate func fill(with path: Path) {
        let logText = try? TextFile(path: path).read()
        fill(with: logText)
    }

    lazy var colorsFromLevel: [XCGLogger.Level: [NSAttributedString.Key: Any]?] = {
        var mapAttributes: [XCGLogger.Level: [NSAttributedString.Key: Any]?] = [:]
        mapAttributes[.info] = [.foregroundColor: ColorCompatibility.label]
        mapAttributes[.debug] = [.foregroundColor: ColorCompatibility.systemBlue]
        mapAttributes[.error] = [.foregroundColor: ColorCompatibility.systemRed]
        mapAttributes[.severe] = [.foregroundColor: UIColor.brown]
        mapAttributes[.warning] = [.foregroundColor: ColorCompatibility.systemOrange]
        mapAttributes[.verbose] = [.foregroundColor: ColorCompatibility.systemGray2]
        return mapAttributes
    }()

    // MARK: action

    @IBAction open func dismiss(_ sender: Any!) {
        self.dismiss(animated: true) {
            self.delegate?.logFormDismiss(logForm: self)
        }
    }

    @IBAction open func refresh(_ sender: Any!) {
        if let button = sender as? UIBarButtonItem {
            button.isEnabled = false
        }
        if let path = path {
            self.fill(with: path)
        }
        DispatchQueue.main.after(1) { // maybe add activity indicator instead of disabling
            self.textView.scrollToTheEnd()
            if let button = sender as? UIBarButtonItem {
                button.isEnabled = true
            }
        }
    }

    @IBAction open func send(_ sender: Any!) {
        self.delegate?.logFormSend(logForm: self)
    }

    // MARK: Storyboardable

    public static var storyboardBundle: Bundle? {
        return Bundle(for: LogForm.self)
    }
}

extension BaseDestination {
    /// Find the log level according to the string outputted.
    static func level(for line: String) -> XCGLogger.Level {
        // XXX do a pattern matching and extract intead
        if line.contains("[Info]") {
           return .info
        } else if line.contains("[Debug]") {
             return .debug
        } else if line.contains("[Error]") {
            return .error
        } else if line.contains("[Warning]") {
            return .warning
        } else if line.contains("[Severe]") {
            return .severe
        } else if line.contains("[Verbose]") {
            return .verbose
        }
        return .none
    }
}

extension LogForm: FeedbackFormDelegate {
    public func send(feedback: Feedback, dismiss: @escaping (Bool) -> Void) {
        (ApplicationFeedback.instance as? ApplicationFeedback)?.send(feedback: feedback, dismiss: dismiss)
    }

    public func discard(feedback: Feedback?) {
         // nothing to do
    }

}

extension UITextView {
    func scrollToTheEnd() {
        self.scrollRangeToVisible(NSRange(location: (self.text as NSString).length, length: 0))
    }
}

extension LogForm: IdentifiableProtocol { // XXX could be generic ?

    public var storyboardIdentifier: String? {
        let clazz = type(of: self)
        let className = stringFromClass(clazz)
        return className
    }

    static var storyboardFromType: UIStoryboard {
        return UIStoryboard(name: String(describing: self), bundle: Bundle(for: LogForm.self))
    }

    static func instantiateNavigationControllerFromType() -> UINavigationController? {
        let initialVC = storyboardFromType.instantiateInitialViewController()
        return initialVC as? UINavigationController
    }

    static func instantiateViewController<T: UIViewController>(ofType type: T.Type) -> T? where T: IdentifiableProtocol {
        return self.storyboardFromType.instantiateViewController(ofType: type)
    }

    static func instantiate() -> LogForm? {
        if let navigationController = LogForm.instantiateNavigationControllerFromType() {
            if let logForm = navigationController.rootViewController as? LogForm {
                return logForm
            }
            if let logForm = LogForm.instantiateViewController(ofType: LogForm.self) {
                navigationController.viewControllers = [logForm]
                return logForm
            }
            return nil
        } else {
            return LogForm.instantiateViewController(ofType: LogForm.self)
        }
    }
}
