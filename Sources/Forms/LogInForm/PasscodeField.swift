//
//  PasscodeField.swift
//  QMobileUI
//
//  Created by Eric Marchand on 09/03/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//
import UIKit

/// A designable field to enter passcode.
@IBDesignable
public class PasscodeField: UIControl {

    // MARK: - Public designable variables

    @IBInspectable public var numberOfDigits: Int = 6 {
        didSet {
            if oldValue != numberOfDigits {
                if passcode.count > numberOfDigits {
                    let endOfString = passcode.index(passcode.startIndex, offsetBy: numberOfDigits)
                    passcode = String(passcode[passcode.startIndex..<endOfString])
                }
                createDigitLabels()
                configureDigitLabels()
            }
        }
    }

    @IBInspectable public var isSecureTextEntry: Bool = false {
        didSet {
            if isSecureTextEntry != oldValue {
                configureDigitLabels()
            }
        }
    }

    @IBInspectable public var passcode: String = "" {
        didSet {
            if oldValue != passcode {
                guard passcode.count <= numberOfDigits else {
                    return
                }
                guard passcode.isNumeric else {
                    return
                }
                configureDigitLabels()
                sendActions(for: .valueChanged)
            }
        }
    }

    @IBInspectable public var spaceBetweenDigits: CGFloat = 10.0 {
        didSet {
            if oldValue != spaceBetweenDigits {
                createDigitLabels()
                configureDigitLabels()
            }
        }

    }

    @IBInspectable public var dashColor: UIColor = ColorCompatibility.systemGray {
        didSet {
            if oldValue != dashColor {
                configureDigitLabels()
            }
        }
    }

    @IBInspectable public var textColor: UIColor = ColorCompatibility.label {
        didSet {
            if oldValue != textColor {
                configureDigitLabels()
            }
        }
    }

    @IBInspectable public var dashBackColor: UIColor = ColorCompatibility.systemGreen {
        didSet {
            if oldValue != dashBackColor {
                configureDigitLabels()
            }
        }
    }

    @IBInspectable public var backColor: UIColor = ColorCompatibility.systemYellow {
        didSet {
            if oldValue != backColor {
                configureDigitLabels()
            }
        }
    }

    @IBInspectable public var emptyDigit: String = "-" {
        didSet {
            if oldValue != emptyDigit {
                configureDigitLabels()
            }
        }
    }

    // MARK: - Private variables
    private var digitLabels: [PasscodeDigitLabel] = []

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    private func configure() {
        addTarget(self, action: #selector(PasscodeField.didTouchUpInside), for: .touchUpInside)
        createDigitLabels()
    }

    private func removeDigitLabels() {
        digitLabels.forEach { label in
            label.removeFromSuperview()
        }
        digitLabels = []
    }
    private func createDigitLabels() {
        removeDigitLabels()
        for _ in 0..<numberOfDigits {
            let numberLabel = PasscodeDigitLabel()
            numberLabel.label.text = emptyDigit
            numberLabel.label.textColor = dashColor
            numberLabel.label.textAlignment = .center
            digitLabels.append(numberLabel)
            addSubview(numberLabel)
        }
        setNeedsLayout()
    }

    // MARK: - UIView

    public override func prepareForInterfaceBuilder() {
        createDigitLabels()
    }

    override public func layoutSubviews() {
        for index in 0..<digitLabels.count {
            let label = digitLabels[index]
            let frame = digitLabelFrame(at: index)
            label.label.font = UIFont.systemFont(ofSize: frame.size.width * 0.9)
            label.label.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
            label.frame = frame
        }
    }

    // MARK: - Private methods

    private func digitLabelFrame(at index: Int) -> CGRect {
        let width = (bounds.size.width - spaceBetweenDigits * (CGFloat(numberOfDigits) - 1.0)) / CGFloat(numberOfDigits)
        let height = bounds.size.height
        // swiftlint:disable:next identifier_name
        let x = (width + spaceBetweenDigits) * CGFloat(index)
        // swiftlint:disable:next identifier_name
        let y = CGFloat(0)
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private func configureDigitLabels() {
        // swiftlint:disable:next identifier_name
        for i in 0..<numberOfDigits {
            let label = digitLabels[i]
            if i < passcode.count {
                let start = passcode.index(passcode.startIndex, offsetBy: i)
                let end = passcode.index(start, offsetBy: 1)
                let number = String(passcode[start..<end])
                label.label.text = isSecureTextEntry ? "●" : number
                label.label.textColor = textColor
                label.backgroundColor = backColor

            } else {
                label.label.text = emptyDigit
                label.label.textColor = dashColor
                label.backgroundColor = dashBackColor
            }
        }
    }

    // MARK: - Handle the touch up event
    @objc private func didTouchUpInside() {
        becomeFirstResponder()
    }

    // MARK: UIResponder
    public override var canBecomeFirstResponder: Bool {
        return true
    }

}

// MARK: UIKeyInput protocol
extension PasscodeField: UIKeyInput {

    public var hasText: Bool {
        return !passcode.isEmpty
    }

    public func insertText(_ text: String) {
        guard passcode.count + text.count <= numberOfDigits else {
            return
        }

        guard text.isNumeric else {
            return
        }

        passcode += text
    }

    public func deleteBackward() {
        if passcode.isEmpty {
            return
        }
        passcode = String(passcode[passcode.startIndex..<passcode.index(before: passcode.endIndex)])
    }

    // MARK: UIKeyboardTrait

    public var keyboardType: UIKeyboardType {
        get {
            return .numberPad
        }
        // swiftlint:disable:next unused_setter_value
        set {}
    }

}

// MARK: internal label
private class PasscodeDigitLabel: UIView {

    lazy var label: UILabel = {
        return UILabel()
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.label.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        self.label.textAlignment = .center
        self.addSubview(self.label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// MARK: internal label
extension String {

    fileprivate var isNumeric: Bool {
        guard let regex = try? NSRegularExpression(pattern: "^[0-9]*$", options: []) else {
            return false
        }
        let range = NSRange(location: 0, length: count)
        return regex.numberOfMatches(in: self, options: [], range: range) == 1
    }
}
