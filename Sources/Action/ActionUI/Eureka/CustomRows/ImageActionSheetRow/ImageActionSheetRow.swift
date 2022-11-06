//
//  ImageActionSheetRow.swift
//  QMobileUI
//
//  Created by emarchand on 04/11/2022.
//  Copyright © 2022 Eric Marchand. All rights reserved.
//

import UIKit
import Eureka

public final class ImageActionSheetRow<T>: _ImageActionSheetRow<AlertSelectorCell<T>>, RowType where T: Equatable {
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

open class _ImageActionSheetRow<Cell: CellType>: AlertOptionsRow<Cell>, PresenterRowType where Cell: BaseCell { // swiftlint:disable:this type_name

    public typealias ProviderType = ImageSelectorAlertController<_ImageActionSheetRow<Cell>>

    public var onPresentCallback: ((FormViewController, ProviderType) -> Void)?
    lazy public var presentationMode: PresentationMode<ProviderType>? = {
        return .presentModally(controllerProvider: ControllerProvider.callback { [weak self] in
            let vc = ImageSelectorAlertController<_ImageActionSheetRow<Cell>>(title: self?.selectorTitle, message: nil, preferredStyle: .actionSheet) // swiftlint:disable:this identifier_name
            if let popView = vc.popoverPresentationController {
                guard let cell = self?.cell, let tableView = cell.formViewController()?.tableView else { fatalError() }
                popView.sourceView = tableView
                popView.sourceRect = tableView.convert(cell.detailTextLabel?.frame ?? cell.textLabel?.frame ?? cell.contentView.frame, from: cell)
            }
            vc.row = self! as AlertOptionsRow
            return vc
        },
                               onDismiss: { [weak self] in
            $0.dismiss(animated: true)
            self?.cell?.formViewController()?.tableView?.reloadData()
        })
    }()

    public required init(tag: String?) {
        super.init(tag: tag)
    }

    open override func customDidSelect() {
        super.customDidSelect()
        if let presentationMode = presentationMode, !isDisabled {
            if let controller = presentationMode.makeController() {
                controller.row = self
                onPresentCallback?(cell.formViewController()!, controller)
                presentationMode.present(controller, row: self, presentingController: cell.formViewController()!)
            } else {
                presentationMode.present(nil, row: self, presentingController: cell.formViewController()!)
            }
        }
    }
}

/// Selector UIAlertController
open class ImageSelectorAlertController<ImageAlertOptionsRow: AlertOptionsProviderRow>: UIAlertController, TypedRowControllerType
where ImageAlertOptionsRow.OptionsProviderType.Option == ImageAlertOptionsRow.Cell.Value, ImageAlertOptionsRow: BaseRow {

    /// The row that pushed or presented this controller
    public var row: RowOf<ImageAlertOptionsRow.Cell.Value>!

    @available(*, deprecated, message: "Use AlertOptionsRow.cancelTitle instead.")
    public var cancelTitle = NSLocalizedString("Cancel", comment: "")

    /// A closure to be called when the controller disappears.
    public var onDismissCallback: ((UIViewController) -> Void)?

    /// Options provider to use to get available options.
    /// If not set will use synchronous data provider built with `row.dataProvider.arrayData`.
    //    public var optionsProvider: OptionsProvider<T>?
    public var optionsProviderRow: ImageAlertOptionsRow {
        return row as Any as! ImageAlertOptionsRow // swiftlint:disable:this force_cast
    }

    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    convenience public init(_ callback: ((UIViewController) -> Void)?) {
        self.init()
        onDismissCallback = callback
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        guard let options = optionsProviderRow.options else { return }
        let cancelTitle = optionsProviderRow.cancelTitle ?? NSLocalizedString("Cancel", comment: "")
        addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: nil))
        for option in options {
            let action = UIAlertAction(title: "", style: .default, handler: { [weak self] _ in
                self?.row.value = option
                self?.onDismissCallback?(self!)
            })

            if var image = UIImage(named: "\(kPrefixImageNamed)\(action.title ?? "")") {
                if image.renderingMode == .automatic {
                    image = image.withRenderingMode(.alwaysOriginal)
                }
                action.leftImage = image
            }
            addAction(action)
        }
    }

}
