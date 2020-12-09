//
//  BarcodeScannerRow.swift
//  QMobileUI
//
//  Created by phimage on 20/10/2020.
//  Copyright © 2020 Eric Marchand. All rights reserved.
//

import UIKit
import AVFoundation
import Eureka
import SwiftMessages
import Prephirences

public final class BarcodeScannerRow: OptionsRow<PushSelectorCell<String>>, PresenterRowType, RowType {

    public typealias PresenterRow = BarcodeScannerRowViewController

    public var presentationMode: PresentationMode<PresenterRow>?
    public var onPresentCallback: ((FormViewController, PresenterRow) -> Void)?

    public required init(tag: String?) {
        super.init(tag: tag)
        let controllerProvider: ControllerProvider<PresenterRow> = ControllerProvider.callback {
            let controller = BarcodeScannerRowViewController()
            controller.modalPresentationStyle = .fullScreen
            return controller
        }
        presentationMode = .presentModally(controllerProvider: controllerProvider, onDismiss: { [weak self] viewController in
            self?.select()
            viewController.dismiss(animated: true)
            })
    }

    public override func customDidSelect() {
        super.customDidSelect()
        guard let presentationMode = presentationMode, !isDisabled else { return }
        if let controller = presentationMode.makeController() {
            controller.row = self
            controller.title = selectorTitle ?? controller.title
            onPresentCallback?(cell.formViewController()!, controller)
            presentationMode.present(controller, row: self, presentingController: self.cell.formViewController()!)
        } else {
            presentationMode.present(nil, row: self, presentingController: self.cell.formViewController()!)
        }
    }

    public override func prepare(for segue: UIStoryboardSegue) {
        super.prepare(for: segue)
        guard let rowVC = segue.destination as? PresenterRow else { return }
        rowVC.title = selectorTitle ?? rowVC.title
        rowVC.onDismissCallback = presentationMode?.onDismissCallback ?? rowVC.onDismissCallback
        onPresentCallback?(cell.formViewController()!, rowVC)
        rowVC.row = self
    }

    public override func customUpdateCell() {
        let imageView: UIImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        imageView.image = UIImage(systemName: "barcode.viewfinder")?.withRenderingMode(.alwaysTemplate)
        imageView.contentMode = .scaleAspectFit
        cell.accessoryView = imageView
   }

}

open class BarcodeScannerViewController: UIViewController {

    open var onDismissCallback: ((UIViewController) -> Void)?

    open var captureSession: AVCaptureSession!
    open var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    open var qrCodeFrameView: UIView!
    open var cancelButton: UIButton!
    open var metadata: String?

    static var defaultSupportedCodeTypes: [AVMetadataObject.ObjectType] {
        let types = Prephirences.sharedInstance["barcode.types"]
        if let types = types as? [String] {
            return types.flatMap({  AVMetadataObject.ObjectType.from($0)})
        } else if let types = types as? String {
            return AVMetadataObject.ObjectType.from(types)
        }
        return [.ean8, .ean13, .code39, .code93, .code128, .qr, .upce, .pdf417]
    }

    open var supportedCodeTypes: [AVMetadataObject.ObjectType] = BarcodeScannerViewController.defaultSupportedCodeTypes

    override public func viewDidLoad() {
        super.viewDidLoad()
        // XXX could use witch AVCaptureDevice.authorizationStatus(for: .video) { if necessary
        // Get camera
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            logger.warning("Failed to get the camera device. Maybe forbidden by user or simulator.")
            SwiftMessages.warning("No camera accessible to scan")
            foreground {
                self.onDismissCallback?(self)
            }
            return
        }
        // launch a capture session
        do {
            captureSession = AVCaptureSession()
            //captureSession.beginConfiguration()
           // captureSession.connections.first?.videoOrientation = .landscapeLeft

            // with camera as input
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(input)

            // and code type detector has output
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = supportedCodeTypes
        } catch {
            captureSession = nil
            logger.error("Error when try to capture \(error)")
            SwiftMessages.warning("Please authorize camera")
            foreground {
                self.onDismissCallback?(self)
            }
            return
        }

        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)

        captureSession.startRunning()

        qrCodeFrameView = UIView()
        qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
        qrCodeFrameView.layer.borderWidth = 2
        view.addSubview(qrCodeFrameView)
        view.bringSubviewToFront(qrCodeFrameView)

        cancelButton = UIButton(frame: CGRect(x: self.view.bounds.width - 80, y: self.view.bounds.height - 80, width: 50, height: 50))
        cancelButton.backgroundColor = UIColor.clear
        cancelButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        cancelButton.setImage(UIImage(systemName: "xmark"), for: .highlighted)
        cancelButton.tintColor = UIColor.white.withAlphaComponent(0.8)
        cancelButton.layer.borderColor = cancelButton.tintColor.cgColor
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.cornerRadius = 25
        cancelButton.layer.masksToBounds = true
        cancelButton.addTarget(self, action: #selector(self.onCancelButton(_:)), for: .touchUpInside)
        view.addSubview(cancelButton)

        DispatchQueue.main.async {
            // self.initiateOrientation
            self.setVideoOrientation()
        }
    }

    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // CLEAN replace with constraints
        if let videoPreviewLayer = videoPreviewLayer {
            videoPreviewLayer.frame = view.layer.bounds
            cancelButton?.frame = CGRect(x: self.view.bounds.width - 80, y: self.view.bounds.height - 80, width: 50, height: 50)
            self.setVideoOrientation()
        }
    }

    func initiateOrientation() {
        if let connection = self.videoPreviewLayer?.connection, connection.isVideoOrientationSupported {
            let windowOrientation = self.view.window?.windowScene?.interfaceOrientation ?? .unknown
            if let videoOrientation = AVCaptureVideoOrientation(interfaceOrientation: windowOrientation) {
                connection.videoOrientation = videoOrientation
            }
        }
    }

    fileprivate func setVideoOrientation() {
        if let connection = self.videoPreviewLayer?.connection, connection.isVideoOrientationSupported {
            let deviceOrientation = UIDevice.current.orientation
            if let newVideoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation) {
                logger.debug("Camera will set orientation \(newVideoOrientation) according to device orientation \(deviceOrientation)")
                connection.videoOrientation = newVideoOrientation
            }
        }
    }

    @objc func onCancelButton(_ sender: UIButton) {
        endSession()
        self.onDismissCallback?(self)
    }

    fileprivate func endSession() {
        self.captureSession?.stopRunning()
        self.captureSession = nil
    }

    open func onMetaDataOutput(_ metadata: String) {
        self.metadata = metadata
    }
}

extension AVMetadataObject.ObjectType {

    static func from(_ string: String) -> [AVMetadataObject.ObjectType] {
        var result: [AVMetadataObject.ObjectType] = []
        for codeString in string.split(separator: ",") {
            switch string.trimmed {
            case "ean8":
                result.append(.ean8)
            case "ean13":
                result.append(.ean13)
            case "ean":
                result.append(contentsOf: [.ean13, .ean8])
            case "code39":
                result.append(.code39)
            case "code93":
                result.append(.code93)
            case "code128":
                result.append(.code128)
            case "code":
                result.append(contentsOf: [.code39, .code93, .code128])
            case "qr":
                result.append(.qr)
            case "upce":
                result.append(.upce)
            case "aztec":
                result.append(.aztec)
            case "pdf417":
                result.append(.pdf417)
            default:
                break
            }
        }
        return result
    }
}

extension AVCaptureVideoOrientation {
    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeRight
        case .landscapeRight: self = .landscapeLeft
        default: return nil
        }
    }

    init?(interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        default: return nil
        }
    }
}

extension BarcodeScannerViewController: AVCaptureMetadataOutputObjectsDelegate {

    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.isEmpty {
            qrCodeFrameView.frame = .zero
        } else if let metadataObj = metadataObjects[0] as? AVMetadataMachineReadableCodeObject, supportedCodeTypes.contains(metadataObj.type) {

            if let barCodeObject = videoPreviewLayer.transformedMetadataObject(for: metadataObj) {
                qrCodeFrameView.frame = barCodeObject.bounds
            }

            if let value = metadataObj.stringValue {
                self.endSession()
                self.onMetaDataOutput(value)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { // add a delay to let user see the detection effect
                    self.onDismissCallback?(self)
                }
            }
        }
    }

}

public class BarcodeScannerRowViewController: BarcodeScannerViewController, TypedRowControllerType {

    public var row: RowOf<String>!

    override open func onMetaDataOutput(_ metadata: String) {
        super.onMetaDataOutput(metadata)
        row.value = metadata
    }

}
