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

public final class OCRRow: OptionsRow<PushSelectorCell<String>>, PresenterRowType, RowType {

    public typealias PresenterRow = OCRViewController

    public var presentationMode: PresentationMode<PresenterRow>?
    public var onPresentCallback: ((FormViewController, PresenterRow) -> Void)?

    public required init(tag: String?) {
        super.init(tag: tag)
        let controllerProvider: ControllerProvider<PresenterRow> = ControllerProvider.callback {
            let controller = OCRViewController()
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
        imageView.image = UIImage(systemName: "rectangle.and.text.magnifyingglass")?.withRenderingMode(.alwaysTemplate)
        imageView.contentMode = .scaleAspectFit
        cell.accessoryView = imageView

        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.lineBreakMode = .byWordWrapping

        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.height = {
            return 100
        }
    }

}
import VisionKit
import Vision

public class OCRViewController: UIViewController, VNDocumentCameraViewControllerDelegate, UIAdaptivePresentationControllerDelegate, TypedRowControllerType {
    public var row: RowOf<String>!
    open var onDismissCallback: ((UIViewController) -> Void)?

    lazy var documentController: VNDocumentCameraViewController = {
        var documentController = VNDocumentCameraViewController()
        documentController.isModalInPresentation = true
        return documentController
    }()

    override public func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.async {
            if VNDocumentCameraViewController.isSupported {
                self.documentController.delegate = self
                self.present(self.documentController, animated: true) {
                    self.documentController.presentationController?.delegate = self
                }
            } else {
                if Platform.isSimulator {
                    SwiftMessages.warning("No camera in simulator")
                } else {
                    SwiftMessages.warning("No camera to scan")
                }
            }
        }
    }

    func recognizeText(from images: [CGImage]) -> String {
        var result = ""
        let textRecognitionRequest = VNRecognizeTextRequest { (request, _) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                logger.warning("The observations to scan are of an unexpected type.")
                return
            }
            let maximumCandidates = 1
            for observation in observations {
                guard let candidate = observation.topCandidates(maximumCandidates).first else { continue }
                result += candidate.string + "\n"
            }
        }
        textRecognitionRequest.recognitionLevel = .accurate
        for image in images {
            let requestHandler = VNImageRequestHandler(cgImage: image, options: [:])

            do {
                try requestHandler.perform([textRecognitionRequest])
            } catch {
                logger.error(error)
            }
            result += "\n\n"
        }
        return result
    }

    // MARK: - VNDocumentCameraViewControllerDelegate

    open func documentCameraViewController(_ picker: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        var images = [CGImage]()
        for pageIndex in 0 ..< scan.pageCount {
            let image = scan.imageOfPage(at: pageIndex)
            if let cgImage = image.cgImage {
                images.append(cgImage)
            }
        }
        row.value = recognizeText(from: images)

        picker.dismiss(animated: true) {
            self.onDismissCallback?(self)
        }
    }

    // The delegate will receive this call when the user cancels.
    open func documentCameraViewControllerDidCancel(_ picker: VNDocumentCameraViewController) {
        picker.dismiss(animated: true) {
            self.onDismissCallback?(self)
        }
    }

    // The delegate will receive this call when the user is unable to scan, with the following error.
    open func documentCameraViewController(_ picker: VNDocumentCameraViewController, didFailWithError error: Error) {
        logger.error("error when scanning document \(error)")
        picker.dismiss(animated: true) {
            self.onDismissCallback?(self)
        }
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    open func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.onDismissCallback?(self)
    }
}
