//  ImageRow.swift
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

public struct ImageRowSourceTypes: OptionSet {

    public let rawValue: Int
    public var imagePickerControllerSourceTypeRawValue: Int { return self.rawValue >> 1 }

    public init(rawValue: Int) { self.rawValue = rawValue }
    init(_ sourceType: ImagePickerController.SourceType) { self.init(rawValue: 1 << sourceType.rawValue) }

    public static let photoLibrary = ImageRowSourceTypes(.photoLibrary)
    public static let camera = ImageRowSourceTypes(.camera)
    public static let all: ImageRowSourceTypes = [camera, photoLibrary]

    var image: (UIImage, CGRect)? {
        var types: [ImagePickerController.SourceType] = []
        var size = CGRect(x: 0, y: 0, width: 0, height: 20)
        if self.contains(.camera) {
            types.append(.camera)
            size = size.with(width: size.width + 20)
        }
        if self.contains(.photoLibrary) {
            types.append(.photoLibrary)
            size = size.with(width: size.width + 20)
        }
        guard let image = types.map({$0.image}).mergeToGrid()?.withRenderingMode(.alwaysTemplate) else {
            return nil
        }
        return (image, size)
    }
}

extension ImageRowSourceTypes {

// MARK: Helpers

    var localizedString: String {
        switch self {
        case ImageRowSourceTypes.camera:
            return "Take photo"
        case ImageRowSourceTypes.photoLibrary:
            return "Photo Library"
        default:
            return ""
        }
    }
}

public enum ImageClearAction {
    case no // swiftlint:disable:this identifier_name
    case yes(style: UIAlertAction.Style)
}

// MARK: Row
 // swiftlint:disable:next type_name
open class _ImageRow<Cell: CellType>: OptionsRow<Cell>, PresenterRowType where Cell: BaseCell, Cell.Value == UIImage {

    public typealias PresenterRow = ImagePickerController
    /// Defines how the view controller will be presented, pushed, etc.
    open var presentationMode: PresentationMode<PresenterRow>?

    /// Will be called before the presentation occurs.
    open var onPresentCallback: ((FormViewController, PresenterRow) -> Void)?

    open var sourceTypes: ImageRowSourceTypes
    open internal(set) var imageURL: URL?
    open var clearAction = ImageClearAction.yes(style: .destructive)

    private var _sourceType = ImagePickerController.SourceType.camera

    public required init(tag: String?) {
        sourceTypes = .all
        super.init(tag: tag)
        refreshAvailableType()
        presentationMode = .presentModally(controllerProvider: ControllerProvider.callback { return ImagePickerController() }, onDismiss: { [weak self] viewController in
            self?.select()
            viewController.dismiss(animated: true)
            })
        self.displayValueFor = nil

    }

    // copy over the existing logic from the SelectorRow
    func displayImagePickerController(_ sourceType: ImagePickerController.SourceType) {
        if let presentationMode = presentationMode, !isDisabled {
            if let controller = presentationMode.makeController() {
                controller.row = self
                controller.sourceType = sourceType
                onPresentCallback?(cell.formViewController()!, controller)
                presentationMode.present(controller, row: self, presentingController: cell.formViewController()!)
            } else {
                _sourceType = sourceType
                presentationMode.present(nil, row: self, presentingController: cell.formViewController()!)
            }
        }
    }

    fileprivate func refreshAvailableType() {
        var availableSources: ImageRowSourceTypes = []

        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            _ = availableSources.insert(.photoLibrary)
        }
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            _ = availableSources.insert(.camera)
        }

        sourceTypes.formIntersection(availableSources)
    }

    /// Extends `didSelect` method
    /// Selecting the Image Row cell will open a popup to choose where to source the photo from,
    /// based on the `sourceTypes` configured and the available sources.
    open override func customDidSelect() {
        guard !isDisabled else {
            super.customDidSelect()
            return
        }
        deselect()

        refreshAvailableType()

        if sourceTypes.isEmpty {
            super.customDidSelect()
            guard let presentationMode = presentationMode else { return }
            if let controller = presentationMode.makeController() {
                controller.row = self
                controller.title = selectorTitle ?? controller.title
                onPresentCallback?(cell.formViewController()!, controller)
                presentationMode.present(controller, row: self, presentingController: self.cell.formViewController()!)
            } else {
                presentationMode.present(nil, row: self, presentingController: self.cell.formViewController()!)
            }
            return
        }

        // Now that we know the number of sources aren't empty, let the user select the source
        let sourceActionSheet = UIAlertController(title: nil, message: selectorTitle, preferredStyle: .actionSheet)
        guard let tableView = cell.formViewController()?.tableView  else { fatalError() }
        if let popView = sourceActionSheet.popoverPresentationController {
            popView.sourceView = tableView
            popView.sourceRect = tableView.convert(cell.accessoryView?.frame ?? cell.contentView.frame, from: cell)
        }
        createOptionsForAlertController(sourceActionSheet)
        if case .yes(let style) = clearAction, value != nil {
            let clearPhotoOption = UIAlertAction(title: NSLocalizedString("Clear Photo", comment: ""), style: style, handler: { [weak self] _ in
                self?.value = nil
                self?.imageURL = nil
                self?.updateCell()
                })
            sourceActionSheet.addAction(clearPhotoOption)
        }
        let actions: [UIAlertAction] = sourceActionSheet.actions
        if actions.count == 1 {
            if let imagePickerSourceType = ImagePickerController.SourceType(rawValue: sourceTypes.imagePickerControllerSourceTypeRawValue) {
                displayImagePickerController(imagePickerSourceType)
            }
        } else {
            let cancelOption = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
            sourceActionSheet.addAction(cancelOption)
            if let presentingViewController = cell.formViewController() {
                presentingViewController.present(sourceActionSheet, animated: true)
            }
        }
    }

    /**
     Prepares the pushed row setting its title and completion callback.
     */
    open override func prepare(for segue: UIStoryboardSegue) {
        super.prepare(for: segue)
        guard let rowVC = segue.destination as? PresenterRow else { return }
        rowVC.title = selectorTitle ?? rowVC.title
        rowVC.onDismissCallback = presentationMode?.onDismissCallback ?? rowVC.onDismissCallback
        onPresentCallback?(cell.formViewController()!, rowVC)
        rowVC.row = self
        rowVC.sourceType = _sourceType
    }

    open override func customUpdateCell() {
        super.customUpdateCell()

        cell.accessoryType = .none
        cell.editingAccessoryView = .none

        if let image = self.value {
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
            imageView.contentMode = .scaleAspectFill
            imageView.image = image
            imageView.clipsToBounds = true

            cell.accessoryView = imageView
            cell.editingAccessoryView = imageView
        } else if let (image, size) = self.sourceTypes.image {
            let imageView = UIImageView(frame: size)
            imageView.contentMode = .scaleAspectFit
            imageView.image = image
            // imageView.clipsToBounds = true

            cell.accessoryView = imageView
            cell.editingAccessoryView = imageView
        } else {
            cell.accessoryView = nil
            cell.editingAccessoryView = nil
        }
    }

}

extension _ImageRow {

    // MARK: Helpers

    func createOptionForAlertController(_ alertController: UIAlertController, sourceType: ImageRowSourceTypes) {
        guard let pickerSourceType = ImagePickerController.SourceType(rawValue: sourceType.imagePickerControllerSourceTypeRawValue), sourceTypes.contains(sourceType) else { return }
        let option = UIAlertAction(title: NSLocalizedString(sourceType.localizedString, comment: ""), style: .default, handler: { [weak self] _ in
            self?.displayImagePickerController(pickerSourceType)
        })
        alertController.addAction(option)
    }

    func createOptionsForAlertController(_ alertController: UIAlertController) {
        createOptionForAlertController(alertController, sourceType: .camera)
        createOptionForAlertController(alertController, sourceType: .photoLibrary)
    }
}

/// A selector row where the user can pick an image
public final class ImageRow: _ImageRow<PushSelectorCell<UIImage>>, RowType {
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}
