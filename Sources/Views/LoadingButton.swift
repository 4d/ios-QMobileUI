//
//  LoadingButton.swift
//  FormEditor
//
//  Created by Eric Marchand on 27/03/2018.
//  Copyright © 2018 4D. All rights reserved.
//
import UIKit

public protocol QAnimatable {
    func startAnimation(completionHandler: (() -> Void)?)
    func stopAnimation(completionHandler: (() -> Void)?)
}
public typealias QAnimatableButton = QAnimatable & UIButton

extension QAnimatable {
    public func startAnimation() {
        self.startAnimation(completionHandler: nil)
    }
    public func stopAnimation() {
        self.stopAnimation(completionHandler: nil)
    }
}

@IBDesignable
open class LoadingButton: QAnimatableButton, UIViewControllerTransitioningDelegate {

    @IBInspectable open var activityIndicatorColor: UIColor = UIColor.white {
        didSet {
            activityIndicator.spinnerColor = activityIndicatorColor
        }
    }

    @IBInspectable open var normalCornerRadius: CGFloat = 0.0 {
        didSet {
            self.layer.cornerRadius = normalCornerRadius
        }
    }

    static var buttonDisabledColor: String = "buttonDisabledColor"

    @IBInspectable open var disabledColor: UIColor =
        UIColor(named: LoadingButton.buttonDisabledColor) ?? ColorCompatibility.systemGray4 {
        didSet {
            configureBackgroundColor()
        }
    }

    // Cache title (removed when animating)
    private var cachedTitle: String?

    /// Cache for background color (changed when disabled)
    private var cachedBackgroundColor: UIColor?

    // Has started on animation
    var hasStartedAnimation: Bool = false

    /// The layer to make activity indicator animation.
    private lazy var activityIndicator: SpinerLayer = {
        let spinLayer = SpinerLayer(frame: self.frame)
        spinLayer.spinnerColor = .white
        self.layer.addSublayer(spinLayer)
        return spinLayer
    }()

    // MARK: init
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.configure()
    }

    public required init!(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.configure()
    }

   private func configure() {
        self.clipsToBounds = true
        cachedBackgroundColor = self.backgroundColor
        configureBackgroundColor()
    }

    override open var isUserInteractionEnabled: Bool {
        didSet {
            configureBackgroundColor()
        }
    }

    // Configure background color according to state.
    open func configureBackgroundColor() {
        if isUserInteractionEnabled {
            self.backgroundColor = cachedBackgroundColor
        } else {
            self.backgroundColor = disabledColor
        }
    }

    // MARK: animation

    open func startAnimation(completionHandler: (() -> Void)? = nil) {
        self.hasStartedAnimation = true
        // Remove the title
        let state: UIControl.State = .normal
        let titleForState = title(for: state)
        if !titleForState.isEmpty {
            self.cachedTitle = titleForState
        }
        self.setTitle("", for: state)

        // Animate radius
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            self.layer.cornerRadius = self.frame.height / 2
        }, completion: { _ in
            let shrinkDuration: CFTimeInterval  = 0.1
            self.shrink(duration: shrinkDuration)
            Timer.schedule(delay: shrinkDuration - 0.25) { _ in
                // And show activity indicator
                self.activityIndicator.startAnimation()
                completionHandler?()
            }
        })
    }

    open func stopAnimation(completionHandler: (() -> Void)? = nil) {
        if !self.hasStartedAnimation {
            completionHandler?()
            return
        }

        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            self.layer.cornerRadius = self.normalCornerRadius
        }, completion: { _ in
            self.reset()
            self.hasStartedAnimation = false
            completionHandler?()
        })
    }

    open func reset() {
        self.activityIndicator.stopAnimation()
        self.layer.removeAllAnimations()
        self.setTitle(self.cachedTitle, for: .normal)
    }

}
