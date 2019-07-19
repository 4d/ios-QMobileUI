//
//  FloatingLabelTextField.swift
//  FormEditor
//
//  Created by Eric Marchand on 24/04/2018.
//  Copyright © 2018 4D. All rights reserved.
//

import UIKit

//swiftlint:disable:next type_body_length
@IBDesignable open class FloatingLabelTextField: UITextField {

    // MARK: Animation timing

    /// The value of the title appearing duration
    @objc dynamic open var titleFadeInDuration: TimeInterval = 0.2
    /// The value of the title disappearing duration
    @objc dynamic open var titleFadeOutDuration: TimeInterval = 0.3

    // MARK: Attributes

    // private cache for text color.
    fileprivate var cachedTextColor: UIColor?

    /// A UIColor value that determines the text color of the editable text
    @IBInspectable override dynamic open var textColor: UIColor? {
        set {
            cachedTextColor = newValue
            configureControl(false)
        }
        get {
            return cachedTextColor
        }
    }

    /// A UIColor value that determines text color of the placeholder label
    @IBInspectable dynamic open var placeholderColor: UIColor = UIColor.systemGray2 {
        didSet {
            updatePlaceholder()
        }
    }

    /// A UIFont value that determines text color of the placeholder label
    @objc dynamic open var placeholderFont: UIFont? {
        didSet {
            updatePlaceholder()
        }
    }

    fileprivate func updatePlaceholder() {
        guard let placeholder = placeholder, let font = placeholderFont ?? font else {
            return
        }
        let color = isEnabled ? placeholderColor : disabledColor
        attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                NSAttributedString.Key.foregroundColor: color, NSAttributedString.Key.font: font
            ]
        )
    }

    /// A UIFont value that determines the text font of the title label
    @objc dynamic open var titleFont: UIFont = .systemFont(ofSize: 13) {
        didSet {
            configureTitleLabel()
        }
    }

    /// A UIColor value that determines the text color of the title label when in the normal state
    @IBInspectable dynamic open var titleColor: UIColor = .systemGray {
        didSet {
            configureTitleColor()
        }
    }

    /// A UIColor value that determines the color of the bottom line when in the normal state
    @IBInspectable dynamic open var lineColor: UIColor = .systemGray2 {
        didSet {
            configureLineView()
        }
    }

    /// A UIColor value that determines the color used for the title label and line when the error message is not `nil`
    @IBInspectable dynamic open var errorColor: UIColor = .systemRed {
        didSet {
            configureColors()
        }
    }

    /// A UIColor value that determines the color used for the title label and line when text field is disabled
    @IBInspectable dynamic open var disabledColor: UIColor = .systemGray5 {
        didSet {
            configureControl()
            updatePlaceholder()
        }
    }

    /// A UIColor value that determines the text color of the title label when editing
    @IBInspectable dynamic open var selectedTitleColor: UIColor = .systemGray2 {
        didSet {
            configureTitleColor()
        }
    }

    /// A UIColor value that determines the color of the line in a selected state
    @IBInspectable dynamic open var selectedLineColor: UIColor = .systemGray2 {
        didSet {
            configureLineView()
        }
    }

    // MARK: Line height

    /// A CGFloat value that determines the height for the bottom line when the control is in the normal state
    @IBInspectable dynamic open var lineHeight: CGFloat = 0.5 {
        didSet {
            configureLineView()
            setNeedsDisplay()
        }
    }

    /// A CGFloat value that determines the height for the bottom line when the control is in a selected state
    @IBInspectable dynamic open var selectedLineHeight: CGFloat = 1.0 {
        didSet {
            configureLineView()
            setNeedsDisplay()
        }
    }

    // MARK: Internal views

    /// The internal `UIView` to display the line below the text input.
    open var lineView: UIView!

    /// The internal `UILabel` that displays the selected, deselected title or error message based on the current state.
    open var titleLabel: UILabel!

    // MARK: Properties

    /// Closure to defined a formatter to display title. By default string are uppercased.
    open var titleFormatter: ((String) -> String) = { (text: String) -> String in
        return text.localizedUppercase
    }

    /// A String value for the error message to display.
    open var errorMessage: String? {
        didSet {
            configureControl(true)
        }
    }

    /// A Boolean value that determines whether the receiver has an error message.
    open var hasErrorMessage: Bool {
        guard let errorMessage = errorMessage else {
            return false
        }
        return !errorMessage.isEmpty
    }

    /// The backing property for the highlighted property
    fileprivate var _isHighlighted: Bool = false

    /// Is high lighted.
    override open var isHighlighted: Bool {
        get {
            return _isHighlighted
        }
        set {
            _isHighlighted = newValue
            configureTitleColor()
            configureLineView()
        }
    }

    /// A `Boolean`` value that determines whether the textfield is being edited or is selected.
    open var isEditingOrSelected: Bool {
        return isEditing || isSelected
    }

    fileprivate var isRenderingInInterfaceBuilder: Bool = false

    /// The text.
    @IBInspectable override open var text: String? {
        didSet {
            configureControl(false)
        }
    }

    /// The placeholder text.
    @IBInspectable override open var placeholder: String? {
        didSet {
            setNeedsDisplay()
            updatePlaceholder()
            configureTitleLabel()
        }
    }

    /// The String to display when the textfield is editing and the input is not empty.
    @IBInspectable open var selectedTitle: String? {
        didSet {
            configureControl()
        }
    }

    /// The String to display when the textfield is not editing and the input is not empty.
    @IBInspectable open var title: String? {
        didSet {
            configureControl()
        }
    }

    /// Is selected.
    open override var isSelected: Bool {
        didSet {
            configureControl(true)
        }
    }

    override open var isSecureTextEntry: Bool {
        set {
            super.isSecureTextEntry = newValue
            // Fix caret position.
            let beginning = beginningOfDocument
            selectedTextRange = textRange(from: beginning, to: beginning)
            let end = endOfDocument
            selectedTextRange = textRange(from: end, to: end)
        }
        get {
            return super.isSecureTextEntry
        }
    }

    // MARK: - Initializers

    override public init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    fileprivate final func configure() {
        borderStyle = .none
        createViews()
        configureColors()
        self.addTarget(self, action: #selector(FloatingLabelTextField.editingChanged), for: .editingChanged)
        configureTextAligment()
    }

    fileprivate func configureTextAligment() {
        if UIApplication.shared.userInterfaceLayoutDirection == .leftToRight {
            textAlignment = .left
            titleLabel.textAlignment = .left
        } else {
            textAlignment = .right
            titleLabel.textAlignment = .right
        }
    }

    @objc open func editingChanged() {
        configureControl(true)
        configureTitleLabel(true)
    }

    // MARK: create components

    fileprivate func createViews() {
        // no border
        createTitleLabel()
        createLineView()
    }

    fileprivate func createTitleLabel() {
        let titleLabel = UILabel()
        titleLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        titleLabel.font = titleFont
        titleLabel.alpha = 0.0
        titleLabel.textColor = titleColor

        addSubview(titleLabel)
        self.titleLabel = titleLabel
    }

    fileprivate func createLineView() {
        if lineView == nil {
            let lineView = UIView()
            lineView.isUserInteractionEnabled = false
            self.lineView = lineView
            configureDefaultLineHeight()
        }

        lineView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        addSubview(lineView)
    }

    fileprivate func configureDefaultLineHeight() {
        let onePixel: CGFloat = 1.0 / UIScreen.main.scale
        lineHeight = 2.0 * onePixel
        selectedLineHeight = 2.0 * self.lineHeight
    }

    // MARK: Responder handling

    @discardableResult override open func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        configureControl(true)
        return result
    }

    @discardableResult override open func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        configureControl(true)
        return result
    }

    /// update colors when is enabled changed
    override open var isEnabled: Bool {
        didSet {
            configureControl()
            updatePlaceholder()
        }
    }

    // MARK: - View updates

    fileprivate func configureControl(_ animated: Bool = false) {
        configureColors()
        configureLineView()
        configureTitleLabel(animated)
    }

    fileprivate func configureLineView() {
        if let lineView = lineView {
            lineView.frame = lineViewRectForBounds(bounds, editing: isEditingOrSelected)
        }
        configureLineColor()
    }

    // MARK: - Colors

    open func configureColors() {
        configureLineColor()
        configureTitleColor()
        configureTextColor()
    }

    fileprivate func configureLineColor() {
        if !isEnabled {
            lineView.backgroundColor = disabledColor
        } else if hasErrorMessage {
            lineView.backgroundColor = errorColor
        } else {
            lineView.backgroundColor = isEditingOrSelected ? selectedLineColor : lineColor
        }
    }

    fileprivate func configureTitleColor() {
        if !isEnabled {
            titleLabel.textColor = disabledColor
        } else if hasErrorMessage {
            titleLabel.textColor = errorColor
        } else {
            if isEditingOrSelected || isHighlighted {
                titleLabel.textColor = selectedTitleColor
            } else {
                titleLabel.textColor = titleColor
            }
        }
    }

    fileprivate func configureTextColor() {
        if !isEnabled {
            super.textColor = disabledColor
        } else if hasErrorMessage {
            super.textColor = errorColor
        } else {
            super.textColor = cachedTextColor
        }
    }

    // MARK: - Title handling

    fileprivate func configureTitleLabel(_ animated: Bool = false) {
        var titleText: String?
        if hasErrorMessage {
            titleText = titleFormatter(errorMessage!)
        } else {
            if isEditingOrSelected {
                titleText = selectedTitleOrTitlePlaceholder()
                if titleText == nil {
                    titleText = titleOrPlaceholder()
                }
            } else {
                titleText = titleOrPlaceholder()
            }
        }
        titleLabel.text = titleText
        titleLabel.font = titleFont

        updateTitleVisibility(animated)
    }

    fileprivate var _isTitleVisible: Bool = false

    open var isTitleVisible: Bool {
        get {
            return hasText || hasErrorMessage || _isTitleVisible
        }
        set {
            setTitleVisible(newValue)
        }
    }

    /// Set the title visible with possible animation.
    open func setTitleVisible(
        _ titleVisible: Bool,
        animated: Bool = false,
        animationCompletion: ((_ completed: Bool) -> Void)? = nil
    ) {
        if _isTitleVisible == titleVisible {
            return
        }
        _isTitleVisible = titleVisible
        configureTitleColor()
        updateTitleVisibility(animated, completion: animationCompletion)
    }

    fileprivate func updateTitleVisibility(_ animated: Bool = false, completion: ((_ completed: Bool) -> Void)? = nil) {
        let alpha: CGFloat = isTitleVisible ? 1.0 : 0.0
        let frame: CGRect = titleLabelRectForBounds(bounds, editing: isTitleVisible)
        let updateBlock = { () -> Void in
            self.titleLabel.alpha = alpha
            self.titleLabel.frame = frame
        }
        if animated {
            let animationOptions: UIView.AnimationOptions = .curveEaseOut
            let duration = isTitleVisible ? titleFadeInDuration : titleFadeOutDuration
            UIView.animate(withDuration: duration, delay: 0, options: animationOptions, animations: { () -> Void in
                updateBlock()
                }, completion: completion)
        } else {
            updateBlock()
            completion?(true)
        }
    }

    // MARK: - Positioning and sizes

    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        let superRect = super.textRect(forBounds: bounds)
        let titleHeight = self.titleHeight

        let rect = CGRect(
            x: superRect.origin.x,
            y: titleHeight,
            width: superRect.size.width,
            height: superRect.size.height - titleHeight - selectedLineHeight
        )
        return rect
    }

    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        let superRect = super.editingRect(forBounds: bounds)
        let titleHeight = self.titleHeight

        let rect = CGRect(
            x: superRect.origin.x,
            y: titleHeight,
            width: superRect.size.width,
            height: superRect.size.height - titleHeight - selectedLineHeight
        )
        return rect
    }

    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        let rect = CGRect(
            x: 0,
            y: titleHeight,
            width: bounds.size.width,
            height: bounds.size.height - titleHeight - selectedLineHeight
        )
        return rect
    }

    open func titleLabelRectForBounds(_ bounds: CGRect, editing: Bool) -> CGRect {
        if editing {
            return CGRect(x: 0, y: 0, width: bounds.size.width, height: titleHeight)
        }
        return CGRect(x: 0, y: titleHeight, width: bounds.size.width, height: titleHeight)
    }

    open func lineViewRectForBounds(_ bounds: CGRect, editing: Bool) -> CGRect {
        let height = editing ? selectedLineHeight : lineHeight
        return CGRect(x: 0, y: bounds.size.height - height, width: bounds.size.width, height: height)
    }

    open var titleHeight: CGFloat {
        if let titleLabel = titleLabel,
            let font = titleLabel.font {
            return font.lineHeight
        }
        return 15.0
    }

    open var textHeight: CGFloat {
        if let font = self.font {
            return font.lineHeight + 7.0
        }
        return 7.0
    }

    // MARK: Interface Builder

    override open func prepareForInterfaceBuilder() {
        if #available(iOS 8.0, *) {
            super.prepareForInterfaceBuilder()
        }

        borderStyle = .none
        isSelected = true
        isRenderingInInterfaceBuilder = true
        configureControl(false)
        invalidateIntrinsicContentSize()
    }

    // MARK: - Layout override

    override open func layoutSubviews() {
        super.layoutSubviews()

        titleLabel.frame = titleLabelRectForBounds(bounds, editing: isTitleVisible || isRenderingInInterfaceBuilder)
        lineView.frame = lineViewRectForBounds(bounds, editing: isEditingOrSelected || isRenderingInInterfaceBuilder)
    }

    override open var intrinsicContentSize: CGSize {
        return CGSize(width: bounds.size.width, height: titleHeight + textHeight)
    }

    // MARK: - Helpers

    fileprivate func titleOrPlaceholder() -> String? {
        guard let title = title ?? placeholder else {
            return nil
        }
        return titleFormatter(title)
    }

    fileprivate func selectedTitleOrTitlePlaceholder() -> String? {
        guard let title = selectedTitle ?? title ?? placeholder else {
            return nil
        }
        return titleFormatter(title)
    }

}
