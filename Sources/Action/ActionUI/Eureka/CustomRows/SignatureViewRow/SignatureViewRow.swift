//
//  SignatureViewRow.swift
//  QMobileUI
//
//  Created by phimage on 23/10/2020.
//  Copyright © 2020 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit
import Eureka
// import DeviceKit

public class SignatureViewCell: Cell<UIImage>, CellType, SignatureViewDelegate {
    @IBOutlet weak var clearBtn: UIImageView!
    @IBOutlet weak var signView: SignatureView!

    @IBOutlet weak var signViewHeightConstraint: NSLayoutConstraint!

    public override func setup() {
        super.setup()
        let width = UIScreen.main.bounds.width
        let height = width * 2 / 3
        self.signViewHeightConstraint.constant = height
        self.height = {return height}
        self.signView.listener = self
        clearBtn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(clearSignature(_:))))
        clearBtn.isUserInteractionEnabled = true
        clearBtn.image = UIImage(systemName: "signature")
    }

    @objc public func clearSignature(_ sign: Any?) {
        self.signView.clearSignature()
        self.signView.listener = self
    }

    public func signatureUpdated(_ image: UIImage?) {
        self.row.value = image

        if image == nil {
            clearBtn.image = UIImage(systemName: "signature")
        } else {
            clearBtn.image = UIImage(systemName: "clear")
        }
    }
}

public final class SignatureViewRow: Row<SignatureViewCell>, RowType {
    public required init(tag: String?) {
        super.init(tag: tag)
        cellProvider = CellProvider<SignatureViewCell>(nibName: "SignatureViewCell")
    }

    public override func customUpdateCell() {
        /*  self.cell?.signView.isOpaque = true
         self.cell?.signView.isUserInteractionEnabled = true*/
        // self.cell?.signView.isExclusiveTouch = true
    }
}

public protocol SignatureViewDelegate: NSObjectProtocol {
    func signatureUpdated(_ image: UIImage?)
}
public protocol SignatureViewProtocol {
    var listener: SignatureViewDelegate? { get set}

    func clearSignature()
    func getSignatureImage() -> UIImage?
}

class SignatureView: UIView, SignatureViewProtocol {

    var subview: (SignatureViewProtocol & UIView)!
    var listener: SignatureViewDelegate? {
        get {
            return subview.listener
        }
        set {
            subview.listener = newValue
        }
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initArguments()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initArguments()
    }
    private func initArguments() {
        /*if false /*Device.current.isPad*/ {
         subview = PencilSignatureView(frame: self.bounds)
         // issue with parent scrolling
         } else {*/
        subview = LegacySignatureView(frame: self.bounds)
        /*}*/
        // backgroundColor = .systemGray6
        // subview.backgroundColor = .red
        // self.insertSubview(subview, at: 1)
        self.addSubview(subview)
        subview.snap(to: self)

    }
    func clearSignature() {
        self.subview.clearSignature()
    }
    func getSignatureImage() -> UIImage? {
        return self.subview.getSignatureImage()
    }
}
/*
import PencilKit

class PencilSignatureView: UIView, PKCanvasViewDelegate, SignatureViewProtocol {
    var listener: SignatureViewDelegate?
    var canvasView: PKCanvasView!
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initArguments()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initArguments()
    }
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    private func initArguments() {
        canvasView = PKCanvasView(frame: self.bounds)
        canvasView.isUserInteractionEnabled = true
        //canvasView.isExclusiveTouch = true
       // canvasView.isScrollEnabled = false
        canvasView.tool = PKInkingTool(.pen, color: .gray, width: 2)
        canvasView.drawingPolicy = .anyInput
        /*if #available(iOS 14.0, *) {
            #if targetEnvironment(simulator)
            canvasView.drawingPolicy = .anyInput
            #endif
        }*/
        self.canvasView.drawing = PKDrawing()
        self.addSubview(canvasView)
        //guard let window = view.window, let toolPicker = PKToolPicker.shared(for: window)
        //else { return }
        // toolPicker.setVisible(true, forFirstResponder: canvasView)
        // toolPicker.addObserver(canvasView)
        //canvasView.becomeFirstResponder()
    }

    func canvasViewDrawingDidChange(_ view: PKCanvasView) {
        listener?.signatureUpdated(getSignatureImage())
    }

    func clearSignature() {
        self.canvasView.drawing = PKDrawing()
        listener?.signatureUpdated(getSignatureImage())
    }

    func getSignatureImage() -> UIImage? {
        return autoreleasepool {
            return canvasView.drawing.image(from: canvasView.bounds, scale: 1.0)
            /*
             // to crop
             let bounds = self.scale(
                canvasView.drawing.bounds.insetBy(dx: -lineWidth/2, dy: -lineWidth/2),
                byFactor: fullRender.scale)
            guard let imageRef: CGImage = fullRender.cgImage?.cropping(to: bounds) else { return nil }
            return UIImage(cgImage: imageRef, scale: scale, orientation: fullRender.imageOrientation)*/
        }
    }
}
*/
class LegacySignatureView: UIView, SignatureViewProtocol {

    var control: Int = 0
    var beizerPath: UIBezierPath!
    var points: [CGPoint] = [CGPoint](repeating: CGPoint(), count: 5)

    var listener: SignatureViewDelegate?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initArguments()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initArguments()
    }
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    private func initArguments() {
        self.backgroundColor = .white
        self.isMultipleTouchEnabled = false
        self.beizerPath = UIBezierPath()
        self.beizerPath.lineWidth = 2
    }

    override func draw(_ rect: CGRect) {
        let color = UIColor.black
        color.setStroke()
        self.beizerPath.stroke()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.control = 0
        if let point = touches.first?.location(in: self) {
            points[0] = point
            let startPoint = points[0]
            let endPoint = CGPoint(x: startPoint.x + 1.5, y: startPoint.y + 2)
            self.beizerPath.move(to: startPoint)
            self.beizerPath.addLine(to: endPoint)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let point = touches.first?.location(in: self) {
            self.control += 1
            points[self.control] = point
            if self.control == 4 {
                points[3] = CGPoint(x: (points[2].x + points[4].x)/2.0, y: (points[2].y + points[4].y)/2.0)
                self.beizerPath.move(to: points[0])
                self.beizerPath.addCurve(to: points[3], controlPoint1: points[1], controlPoint2: points[2])
                self.setNeedsDisplay()
                points[0] = points[3]
                points[1] = points[4]
                self.control = 1
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        listener?.signatureUpdated(getSignatureImage())
    }

    func setLineSize(lineSize: CGFloat) {
        self.beizerPath.lineWidth = lineSize
    }

    func clearSignature() {
        self.beizerPath.removeAllPoints()
        self.setNeedsDisplay()
        logger.debug("Signature cleared")
        listener?.signatureUpdated(getSignatureImage())
    }

    func getSignatureImage() -> UIImage? {
        if self.beizerPath.isEmpty {
            return nil
        }
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
