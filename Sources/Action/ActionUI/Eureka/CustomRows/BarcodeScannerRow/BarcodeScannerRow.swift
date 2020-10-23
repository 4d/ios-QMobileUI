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

public final class BarcodeScannerRow: OptionsRow<PushSelectorCell<String>>, PresenterRowType, RowType {

    public typealias PresenterRow =  BarcodeScannerViewController

    public var presentationMode: PresentationMode<PresenterRow>?
    public var onPresentCallback: ((FormViewController, PresenterRow) -> Void)?

    public required init(tag: String?) {
        super.init(tag: tag)
        presentationMode = .presentModally(controllerProvider: ControllerProvider.callback { return BarcodeScannerViewController() }, onDismiss: { [weak self] viewController in
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
}

public class BarcodeScannerViewController: UIViewController, TypedRowControllerType {

    public var row: RowOf<String>!
    public var onDismissCallback: ((UIViewController) -> Void)?

    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?

    private let supportedCodeTypes: [AVMetadataObject.ObjectType] = [.ean8, .ean13, .code39, .code93, .code128, .qr, .upce]

    override public func viewDidLoad() {
        super.viewDidLoad()

        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) else {
            logger.warning("Failed to get the camera device. Maybe forbidden by user or simulator.")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)

            captureSession.addInput(input)

            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)

            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = supportedCodeTypes

        } catch {
            logger.error("Error when try to capture \(error)")
            return
        }

        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)

        captureSession.startRunning()

        qrCodeFrameView = UIView()

        if let qrCodeFrameView = qrCodeFrameView {
            qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView.layer.borderWidth = 2
            view.addSubview(qrCodeFrameView)
            view.bringSubviewToFront(qrCodeFrameView)
        }
    }

}

extension BarcodeScannerViewController: AVCaptureMetadataOutputObjectsDelegate {

    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {

        if metadataObjects.isEmpty {
            qrCodeFrameView?.frame = CGRect.zero
            return
        }

        if let metadataObj = metadataObjects[0] as? AVMetadataMachineReadableCodeObject, supportedCodeTypes.contains(metadataObj.type) {

            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds

            if metadataObj.stringValue != nil {
                row.value = metadataObj.stringValue
                onDismissCallback?(self)
            }
        }
    }

}
