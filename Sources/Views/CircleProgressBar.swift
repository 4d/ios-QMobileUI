//
//  CircleProgressBar.swift
//  New Project
//
//  Created by Eric Marchand on 17/05/2018.
//  Copyright © 2018 My Company. All rights reserved.
//

import UIKit
import IBAnimatable

@IBDesignable
open class CircleProgressBar: UIView {

    @IBInspectable var percent: CGFloat = 0.90
    @IBInspectable var barColor: UIColor = ColorCompatibility.systemBlue
    @IBInspectable var bgColor: UIColor = .clear
    @IBInspectable var shadownColor: UIColor = ColorCompatibility.label
    @IBInspectable var thickness: CGFloat = 20
    @IBInspectable var bgThickness: CGFloat = 20
    @IBInspectable var isHalfBar: Bool = false
    @IBInspectable var oldpercent: CGFloat = 0

    let arc = CAShapeLayer()
    let arc2 = CAShapeLayer()

    @objc dynamic public var graphnumber: NSNumber? {
        get {
            return (percent / 100) as NSNumber
        }
        set {
            oldpercent = self.percent
            guard let number = newValue else {
                self.percent = .infinity
                return
            }
            percent = (CGFloat(number.doubleValue)) / 100
            setNeedsDisplay()

        }
    }

    override open func draw(_ rect: CGRect) {
        // swiftlint:disable:next identifier_name
        let x = self.bounds.midX
        // swiftlint:disable:next identifier_name
        let y = self.bounds.midY
        var strokeStart: CGFloat = 0
        var strokeEnd: CGFloat = percent
        let degrees = 270.0
        let radians = CGFloat(degrees * Double.pi / 180)
        layer.transform = CATransform3DMakeRotation(radians, 0.0, 0.0, 1.0)
        var size = self.frame.size.width
        if self.frame.size.height < size {
            size = self.frame.size.height
        }
        size -= 0
        if self.isHalfBar {
            strokeStart = 0.2
            strokeEnd = (strokeEnd / 1.2) + 0.18
            let degrees = 55.0
            let radians = CGFloat(degrees * Double.pi / 180)
            layer.transform = CATransform3DMakeRotation(radians, 0.0, 0.0, 1.0)
        }
        let path = UIBezierPath(ovalIn: CGRect(x: (x - (68/2)), y: (y - (68/2)), width: 68, height: 68)).cgPath
        self.addOval(self.bgThickness,
                     path: path,
                     strokeStart: strokeStart,
                     strokeEnd: 1.0,
                     strokeColor: self.bgColor,
                     fillColor: .clear,
                     shadowRadius: 0,
                     shadowOpacity: 0,
                     shadowOffsset: .zero)
        self.addOval2(self.thickness,
                      path: path,
                      strokeStart: strokeStart,
                      strokeEnd: strokeEnd,
                      strokeColor: self.barColor,
                      fillColor: .clear,
                      shadowRadius: 0,
                      shadowOpacity: 0,
                      shadowOffsset: .zero)
    }

    // swiftlint:disable:next function_parameter_count
    open func addOval(_ lineWidth: CGFloat,
                      path: CGPath,
                      strokeStart: CGFloat,
                      strokeEnd: CGFloat,
                      strokeColor: UIColor,
                      fillColor: UIColor,
                      shadowRadius: CGFloat,
                      shadowOpacity: Float,
                      shadowOffsset: CGSize) {
        if oldpercent == .infinity {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = strokeStart
            animation.toValue = strokeEnd
            animation.duration = 1.5
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            arc.add(animation, forKey: "drawLineAnimation")
        }
        arc.lineWidth = lineWidth
        arc.path = path
        arc.strokeStart = strokeStart
        arc.strokeEnd = strokeEnd
        arc.strokeColor = strokeColor.cgColor
        arc.fillColor = fillColor.cgColor
        arc.shadowColor = shadownColor.cgColor
        arc.shadowRadius = shadowRadius
        arc.shadowOpacity = shadowOpacity
        arc.shadowOffset = shadowOffsset
        arc.opacity = 0.2
        arc.lineCap = .round
        layer.addSublayer(arc)
    }

    // swiftlint:disable:next function_parameter_count
    open func addOval2(_ lineWidth: CGFloat,
                       path: CGPath,
                       strokeStart: CGFloat,
                       strokeEnd: CGFloat,
                       strokeColor: UIColor,
                       fillColor: UIColor,
                       shadowRadius: CGFloat,
                       shadowOpacity: Float,
                       shadowOffsset: CGSize) {
        if oldpercent == .infinity {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = strokeStart
            animation.toValue = strokeEnd
            animation.duration = 1.5
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            arc2.add(animation, forKey: "drawLineAnimation")
        }
        arc2.lineWidth = lineWidth
        arc2.path = path
        arc2.strokeStart = strokeStart
        arc2.strokeEnd = strokeEnd
        arc2.strokeColor = strokeColor.cgColor
        arc2.fillColor = fillColor.cgColor
        arc2.shadowColor = shadownColor.cgColor
        arc2.shadowRadius = shadowRadius
        arc2.shadowOpacity = shadowOpacity
        arc2.shadowOffset = shadowOffsset
        arc2.lineCap = .round
        layer.addSublayer(arc2)
    }

}
