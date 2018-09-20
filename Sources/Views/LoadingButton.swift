//
//  LoadingButton.swift
//  FormEditor
//
//  Created by Eric Marchand on 27/03/2018.
//  Copyright © 2018 4D. All rights reserved.
//
import UIKit

@IBDesignable
open class LoadingButton: UIButton, UIViewControllerTransitioningDelegate {

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

    @IBInspectable dynamic open var disabledColor: UIColor =
        UIColor(named: LoadingButton.buttonDisabledColor) ?? UIColor(white: 0.88, alpha: 1.0) {
        didSet {
            configureBackgroundColor()
        }
    }

    /// Cache title (removed when animating)
    private var cachedTitle: String?
    /// Cache for background color (changed when disabled)
    private var cachedBackgroundColor: UIColor?

    /// The layer to make activity indicator animation.
    private lazy var activityIndicator: SpinerLayer = {
        let spinLayer = SpinerLayer(frame: self.frame)
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
        activityIndicator.spinnerColor = activityIndicatorColor
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

    open func startAnimation() {
        // Remove the title
        let state: UIControl.State = .normal
        self.cachedTitle = title(for: state)
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
            }
        })
    }

    open func stopAnimation(completionHandler: (() -> Void)? = nil) {
        /*self.expand { // Maybe let transition do this animation*/
        completionHandler?()
        // Reset
        Timer.schedule(delay: 1) { _ in
            self.reset()
        }
        /*}*/
        self.activityIndicator.stopAnimation()
    }

    open func reset() {
        self.layer.removeAllAnimations()
        self.setTitle(self.cachedTitle, for: .normal)
        self.activityIndicator.stopAnimation()
    }

}
