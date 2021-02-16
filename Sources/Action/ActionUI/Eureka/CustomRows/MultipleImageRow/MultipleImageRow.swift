//
//  MultipleImageRow.swift
//  QMobileUI
//
//  Created by Eric Marchand on 09/12/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation

import UIKit
import Eureka

// MARK: Row
 // swiftlint:disable:next type_name
open class _MultipleImageRow<Cell: CellType>: OptionsRow<Cell>, PresenterRowType where Cell: BaseCell, Cell.Value == [UIImage] {

    public typealias PresenterRow = MultipleImagePickerController

    /// Defines how the view controller will be presented, pushed, etc.
    open var presentationMode: PresentationMode<PresenterRow>?

    /// Will be called before the presentation occurs.
    open var onPresentCallback: ((FormViewController, PresenterRow) -> Void)?

    open var sourceTypes: ImageRowSourceTypes
    open internal(set) var imageURLs: [URL?] = []
    open var clearAction = ImageClearAction.yes(style: .destructive)

    private var _sourceType = UIImagePickerController.SourceType.camera

    public required init(tag: String?) {
        sourceTypes = .all
        super.init(tag: tag)
        presentationMode = .presentModally(controllerProvider: ControllerProvider.callback { return MultipleImagePickerController() }, onDismiss: { [weak self] viewController in
            self?.select()
            viewController.dismiss(animated: true)
            })
        self.displayValueFor = nil

    }

    // copy over the existing logic from the SelectorRow
    func displayImagePickerController(_ sourceType: UIImagePickerController.SourceType) {
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

    /// Extends `didSelect` method
    /// Selecting the Image Row cell will open a popup to choose where to source the photo from,
    /// based on the `sourceTypes` configured and the available sources.
    open override func customDidSelect() {
        guard !isDisabled else {
            super.customDidSelect()
            return
        }
        deselect()

        var availableSources: ImageRowSourceTypes = []

        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            _ = availableSources.insert(.photoLibrary)
        }
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            _ = availableSources.insert(.camera)
        }
        sourceTypes.formIntersection(availableSources)

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
                self?.imageURLs = []
                self?.updateCell()
                })
            sourceActionSheet.addAction(clearPhotoOption)
        }
        let actions: [UIAlertAction] = sourceActionSheet.actions
        let count: Int = actions.count
        if count == 1 {
            if let imagePickerSourceType = UIImagePickerController.SourceType(rawValue: sourceTypes.imagePickerControllerSourceTypeRawValue) {
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

        if let images = self.value {
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
            imageView.contentMode = .scaleAspectFill
            imageView.image = images.mergeToGrid()
            imageView.clipsToBounds = true

            cell.accessoryView = imageView
            cell.editingAccessoryView = imageView
        } else {
            cell.accessoryView = nil
            cell.editingAccessoryView = nil
        }
    }

    open func position(of image: UIImage) -> Int? {
        guard let images = self.value  else { return nil }
        for (index, value) in images.enumerated() where value == image {
            return index
        }
        return nil
    }

    open func imageURL(for image: UIImage) -> URL? {
        guard let position = position(of: image) else { return nil }
        guard position >= self.imageURLs.count else {
            assertionFailure("imageURLS count could not provide image url at \(position)")
            return nil
        }
        return self.imageURLs[position]
    }

}

extension _MultipleImageRow {

// MARK: Helpers

    func createOptionForAlertController(_ alertController: UIAlertController, sourceType: ImageRowSourceTypes) {
        guard let pickerSourceType = UIImagePickerController.SourceType(rawValue: sourceType.imagePickerControllerSourceTypeRawValue), sourceTypes.contains(sourceType) else { return }
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
public final class MultipleImageRow: _MultipleImageRow<PushSelectorCell<[UIImage]>>, RowType {
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}
