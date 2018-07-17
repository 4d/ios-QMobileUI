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

open class LogForm: UIViewController, UINavigationBarDelegate {

    var colorize = true

    private let textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.dataDetectorTypes = UIDataDetectorTypes()

        return textView
    }()

    private let navigationBar: UINavigationBar = {
        let navigationBar = UINavigationBar()
        navigationBar.isTranslucent = false
        navigationBar.backgroundColor = .white

        return navigationBar
    }()

    private let standaloneItem: UINavigationItem = {
        let standaloneItem = UINavigationItem()
        standaloneItem.titleView = UILabel()

        return standaloneItem
    }()

    // MARK: - life

    override open func viewDidLoad() {
        super.viewDidLoad()
    }
    public func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureTextView()

        standaloneItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(self.dismiss(_:)))

        navigationBar.delegate = self
        navigationBar.items = [standaloneItem]

       /* navigationBar.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        navigationBar.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true

        if navigationController != nil {
            navigationItem.titleView = standaloneItem.titleView
            navigationBar.isHidden = true
        } else {
            navigationBar.isHidden = false
        }*/

        textView.scrollRangeToVisible(NSRange(location: (textView.text as NSString).length, length: 0))
    }

    @objc func dismiss(_ sender: Any?) {
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: - setup
    func configureTextView() {
        view.addSubview(textView)

        textView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        textView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 0).isActive = true
        textView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: 0).isActive = true
        textView.heightAnchor.constraint(equalTo: view.heightAnchor, constant: 0).isActive = true
    }

    // MARK: - Fill

    func viewLog(in path: Path, from viewController: UIViewController) {
        let logText = try? TextFile(path: path).read()
        if colorize {
            let mutableAttr = NSMutableAttributedString()
            let lines = logText?.split(separator: "\n")
            for line in lines ?? [] {
                mutableAttr.append(NSAttributedString(string: String(line), attributes: mapAttributes[level(for: String(line))] ?? [:]))
                mutableAttr.append(NSAttributedString(string: "\n"))
            }
            textView.attributedText = mutableAttr

        } else {
            textView.text = logText
        }
        viewController.show(self, sender: viewController)
    }

    func level(for line: String) -> XCGLogger.Level {
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

    lazy var mapAttributes: [XCGLogger.Level: [NSAttributedStringKey: Any]?] = {
        var mapAttributes: [XCGLogger.Level: [NSAttributedStringKey: Any]?] = [:]
        mapAttributes[.info] = [.foregroundColor: UIColor.black]
        mapAttributes[.debug] = [.foregroundColor: UIColor.blue]
        mapAttributes[.error] = [.foregroundColor: UIColor.red]
        mapAttributes[.severe] = [.foregroundColor: UIColor.brown]
        mapAttributes[.warning] = [.foregroundColor: UIColor.orange]
        mapAttributes[.verbose] = [.foregroundColor: UIColor.lightGray]

        return mapAttributes
    }()
}
