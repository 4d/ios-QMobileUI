//  ImagePickerController.swift
//  Eureka ( https://github.com/xmartlabs/Eureka )
//
//  Copyright (c) 2016 Xmartlabs SRL ( http://xmartlabs.com )
//
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import UIKit
import Eureka
import PhotosUI
import VisionKit

/// Selector Controller used to pick an image
open class ImagePickerController: UIViewController,
                                  TypedRowControllerType,
                                  UIImagePickerControllerDelegate,
                                  PHPickerViewControllerDelegate,
                                  VNDocumentCameraViewControllerDelegate,
                                  UINavigationControllerDelegate,
                                  UIAdaptivePresentationControllerDelegate {

    public enum SourceType: Int, CaseIterable {
        case photoLibrary = 0
        case camera = 1
        case document = 2

        var uikit: UIImagePickerController.SourceType {
            switch self {
            case .camera:
                return .camera
            case .photoLibrary:
                return .photoLibrary
            case .document:
                assertionFailure("cannot convert document source type")
                return .savedPhotosAlbum
            }
        }
        var image: UIImage {
            switch self {
            case .camera:
                return  UIImage(systemName: "camera")!
            case .photoLibrary:
                return UIImage(systemName: "photo.on.rectangle.angled")!
            case .document:
                return UIImage(systemName: "doc.text.viewfinder")!
            }
        }
    }

    var sourceType: SourceType = .photoLibrary

    /// The row that pushed or presented this controller
    public var row: RowOf<UIImage>!

    /// A closure to be called when the controller disappears.
    public var onDismissCallback: ((UIViewController) -> Void)?

    lazy var cameraController: UIImagePickerController = {
        var controller = UIImagePickerController()
        controller.allowsEditing = true
        return controller
    }()
    lazy var photoLibraryController: PHPickerViewController = {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        var imagePickerController = PHPickerViewController(configuration: configuration)
        imagePickerController.isModalInPresentation = true
        return imagePickerController
    }()
    lazy var documentController: VNDocumentCameraViewController = {
        var documentController = VNDocumentCameraViewController()
        documentController.isModalInPresentation = true
        return documentController
    }()

    /*lazy var colorPicker: UIColorPickerViewController = {
        let colorPicker = UIColorPickerViewController()
        colorPicker.supportsAlpha = false
        return colorPicker
    }()*/

    fileprivate func showPicker() {
        switch sourceType {
        case .camera:
            cameraController.sourceType = .camera
            cameraController.delegate = self
            cameraController.view.frame = self.view.frame
            self.present(cameraController, animated: true) {
                self.cameraController.presentationController?.delegate = self
            }
        case .photoLibrary:
            photoLibraryController.delegate = self
            self.present(photoLibraryController, animated: true) {
                self.photoLibraryController.presentationController?.delegate = self
            }
        case .document:
            documentController.delegate = self
            self.present(documentController, animated: true) {
                self.documentController.presentationController?.delegate = self
            }
        }
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.isModalInPresentation = true
        DispatchQueue.main.async {
            self.showPicker()
        }
    }

    // MARK: - UIImagePickerControllerDelegate

    open func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        (row as? ImageRow)?.imageURL = info[.imageURL] as? URL
        row.value = info[.originalImage] as? UIImage
        cameraController.dismiss(animated: true) {
            self.onDismissCallback?(self)
        }
    }

    open func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        cameraController.dismiss(animated: true) {
            self.onDismissCallback?(self)
        }
    }

    // MARK: - PHPickerViewControllerDelegate

    open func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard let itemProvider = results.first?.itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) else {
            picker.dismiss(animated: true) {
                self.onDismissCallback?(self)
            }
            return
        }
        itemProvider.loadObject(ofClass: UIImage.self) { [weak self]  image, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                // (row as? ImageRow)?.imageURL = info[.imageURL] as? URL
                self.row.value = image as? UIImage
                picker.dismiss(animated: true) {
                    self.onDismissCallback?(self)
                }
            }
        }
    }

    // MARK: - VNDocumentCameraViewControllerDelegate
    open func documentCameraViewController(_ picker: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        // for pageIndex in 0 ..< scan.pageCount {
        if scan.pageCount > 0 {
            row.value = scan.imageOfPage(at: 0)
        }
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
/*
extension ImagePickerController: UIColorPickerViewControllerDelegate {

    //  func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController)

    /// In presentations (except popovers) the color picker shows a close button. If the close button is tapped,
    /// the view controller is dismissed and `colorPickerViewControllerDidFinish:` is called. Can be used to
    /// animate alongside the dismissal.
    public func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {

        // SwiftMessages.info(viewController.selectedColor.hexString)
        row.value = UIImage(color: viewController.selectedColor)
        viewController.dismiss(animated: true) {
            self.onDismissCallback?(self)
        }
    }

}
public extension UIImage {
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 10, height: 10)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}*/
