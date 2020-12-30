//
//  LinearProgressBar.swift
//  QMobileUI
//
//  Created by Eric Marchand on 29/12/2020.
//  Copyright © 2020 4D. All rights reserved.
//

import UIKit

public enum LinearProgressBarState {
    case determinate(percentage: CGFloat)
    case indeterminate
}

open class LinearProgressBar: UIView {

    static let progressBarViewTag = 45071692

    private let firstProgressComponent = CAShapeLayer()
    private let secondProgressComponent = CAShapeLayer()
    private lazy var progressComponents = [firstProgressComponent, secondProgressComponent]

    private(set) var isAnimating = false
    open private(set) var state: LinearProgressBarState = .indeterminate
    var animationDuration: TimeInterval = 2.5

    open var progressBarWidth: CGFloat = 2.0 {
        didSet {
            updateProgressBarWidth()
        }
    }

    open var progressBarColor: UIColor = UIColor(named: "progress") ?? UIColor(named: "BackgroundColor") ?? .systemBlue {
        didSet {
            updateProgressBarColor()
        }
    }

    open var cornerRadius: CGFloat = 0 {
        didSet {
            updateCornerRadius()
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override open func layoutSubviews() {
        updateLineLayers()
        super.layoutSubviews()
    }

    private func setup() {
        clipsToBounds = true
        progressComponents.forEach {
            $0.fillColor = progressBarColor.cgColor
            $0.lineWidth = progressBarWidth
            $0.strokeColor = progressBarColor.cgColor
            $0.strokeStart = 0
            $0.strokeEnd = 0
            layer.addSublayer($0)
        }
        updateLineLayers()
    }

    private func updateLineLayers() {
        let bounds = self.bounds
        frame = CGRect(x: frame.minX, y: frame.minY, width: bounds.width, height: progressBarWidth)

        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: 0, y: bounds.midY))
        linePath.addLine(to: CGPoint(x: bounds.width, y: bounds.midY))

        progressComponents.forEach {
            $0.path = linePath.cgPath
            $0.frame = bounds
        }
    }

    private func updateProgressBarColor() {
        progressComponents.forEach {
            $0.fillColor = progressBarColor.cgColor
            $0.strokeColor = progressBarColor.cgColor
        }
    }

    private func updateProgressBarWidth() {
        progressComponents.forEach {
            $0.lineWidth = progressBarWidth
        }
        updateLineLayers()
    }

    private func updateCornerRadius() {
        layer.cornerRadius = cornerRadius
    }

    func forceBeginRefreshing() {
        isAnimating = false
        startAnimating()
    }

    open func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true
        applyProgressAnimations()
    }

    open func stopAnimating(completion: (() -> Void)? = nil) {
        guard isAnimating else { return }
        isAnimating = false
        removeProgressAnimations()
        completion?()
    }

    // MARK: - Private

    private func applyProgressAnimations() {
        applyFirstComponentAnimations(to: firstProgressComponent)
        applySecondComponentAnimations(to: secondProgressComponent)
    }

    private func applyFirstComponentAnimations(to layer: CALayer) {
        let strokeEndAnimation = CAKeyframeAnimation(keyPath: "strokeEnd")
        strokeEndAnimation.values = [0, 1]
        strokeEndAnimation.keyTimes = [0, NSNumber(value: 1.2 / animationDuration)]
        strokeEndAnimation.timingFunctions = [CAMediaTimingFunction(name: .easeOut),
                                              CAMediaTimingFunction(name: .easeOut)]

        let strokeStartAnimation = CAKeyframeAnimation(keyPath: "strokeStart")
        strokeStartAnimation.values = [0, 1.2]
        strokeStartAnimation.keyTimes = [NSNumber(value: 0.25 / animationDuration),
                                         NSNumber(value: 1.8 / animationDuration)]
        strokeStartAnimation.timingFunctions = [CAMediaTimingFunction(name: .easeIn),
                                                CAMediaTimingFunction(name: .easeIn)]

        [strokeEndAnimation, strokeStartAnimation].forEach {
            $0.duration = animationDuration
            $0.repeatCount = .infinity
        }

        layer.add(strokeEndAnimation, forKey: "firstComponentStrokeEnd")
        layer.add(strokeStartAnimation, forKey: "firstComponentStrokeStart")

    }

    private func applySecondComponentAnimations(to layer: CALayer) {
        let strokeEndAnimation = CAKeyframeAnimation(keyPath: "strokeEnd")
        strokeEndAnimation.values = [0, 1.1]
        strokeEndAnimation.keyTimes = [NSNumber(value: 1.375 / animationDuration), 1]

        let strokeStartAnimation = CAKeyframeAnimation(keyPath: "strokeStart")
        strokeStartAnimation.values = [0, 1]
        strokeStartAnimation.keyTimes = [NSNumber(value: 1.825 / animationDuration), 1]

        [strokeEndAnimation, strokeStartAnimation].forEach {
            $0.timingFunctions = [CAMediaTimingFunction(name: .easeOut),
                                  CAMediaTimingFunction(name: .easeOut)]
            $0.duration = animationDuration
            $0.repeatCount = .infinity
        }

        layer.add(strokeEndAnimation, forKey: "secondComponentStrokeEnd")
        layer.add(strokeStartAnimation, forKey: "secondComponentStrokeStart")
    }

    private func removeProgressAnimations() {
        progressComponents.forEach { $0.removeAllAnimations() }
    }

    fileprivate func attachToTop(of superview: UIView) {
        let view = self
        superview.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        let guide = superview.safeAreaLayoutGuide

        view.trailingAnchor.constraint(equalTo: guide.trailingAnchor).isActive = true
        view.leadingAnchor.constraint(equalTo: guide.leadingAnchor).isActive = true
        view.topAnchor.constraint(equalTo: guide.topAnchor).isActive = true
        view.heightAnchor.constraint(equalToConstant: progressBarWidth).isActive = true
    }

    @discardableResult
    open class func showProgressBar(_ parentView: UIView) -> UIView {
        let progressBar = LinearProgressBar(frame: parentView.frame)
        progressBar.tag = progressBarViewTag
        progressBar.attachToTop(of: parentView)
        progressBar.startAnimating()
        return progressBar
    }

    open class func removeAllProgressBars(_ parentView: UIView) {
        parentView.subviews
            .filter { $0.tag == progressBarViewTag }
            .forEach { view in
                guard let view = view as? LinearProgressBar else { return }
                view.stopAnimating {
                    view.removeFromSuperview()
                }
        }
    }
}
