//
//  ImagePickerRow.swift
//  QMobileUI
//
//  Created by emarchand on 04/11/2022.
//  Copyright © 2022 Eric Marchand. All rights reserved.
//

import UIKit
import Eureka

open class ImagePickerCell<T>: Cell<T>, CellType, UIPickerViewDataSource, UIPickerViewDelegate where T: Equatable {

    @IBOutlet public weak var picker: UIPickerView!

    fileprivate var pickerRow: _ImagePickerRow<T>? { return row as? _ImagePickerRow<T> }

    public required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let pickerView = UIPickerView()
        self.picker = pickerView
        self.picker?.translatesAutoresizingMaskIntoConstraints = false

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.contentView.addSubview(pickerView)
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[picker]-0-|", options: [], metrics: nil, views: ["picker": pickerView]))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[picker]-0-|", options: [], metrics: nil, views: ["picker": pickerView]))
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    open override func setup() {
        super.setup()
        accessoryType = .none
        editingAccessoryType = .none
        height = { UITableView.automaticDimension }
        picker.delegate = self
        picker.dataSource = self
    }

    open override func update() {
        super.update()
        textLabel?.text = nil
        detailTextLabel?.text = nil
        picker.reloadAllComponents()
    }

    deinit {
        picker?.delegate = nil
        picker?.dataSource = nil
    }

    open func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    open func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerRow?.options.count ?? 0
    }

    open func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let imageView = UIImageView(frame: pickerView.frame)
        imageView.contentMode = .center
        let value = pickerRow?.options[row]

        if let choiceList = value as? ChoiceListItemImageNamed,
           let text = choiceList.imageNameKey,
           let image = UIImage(named: "\(kPrefixImageNamed)\(text)") {
            imageView.image = image
        }
        return imageView
    }

    open func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if let picker = pickerRow, !picker.options.isEmpty {
            picker.value = picker.options[row]
        }
    }

}

/*
    fileprivate var pickerRow: _ImagePickerRow<T>? { return row as? _ImagePickerRow<T> }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    open override func update() {
        super.update()
        if let selectedValue = pickerRow?.value, let index = pickerRow?.options.firstIndex(of: selectedValue) {
            picker.selectRow(index, inComponent: 0, animated: true)
        }
    }

    open func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }

    override open func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerRow?.options.count ?? 0
    }

    override open func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return nil // pickerRow?.displayValueFor?(pickerRow?.options[row])
    }

    override open func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if let picker = pickerRow, !picker.options.isEmpty {
            picker.value = picker.options[row]
        }
    }

    open func pickerView(pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 60
    }

    open func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return pickerView.frame.size.width
    }

    open func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        let imageView = UIImageView(frame: pickerView.frame)

        let value = pickerRow?.options[row]

        if let text = value, let image = UIImage(named: "\(kPrefixImageNamed)\(text)") {
            imageView.image = image
        }
        let lable = UILabel()
        lable.text = "azeaze"
        return lable
    }

    open override func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return nil
    }
}
*/
/// A generic row where the user can pick an option from a picker view
public final class ImagePickerRow<T>: _ImagePickerRow<T>, RowType where T: Equatable {

    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

open class _ImagePickerRow<T>: Row<ImagePickerCell<T>> where T: Equatable { // swiftlint:disable:this type_name

    open var options = [T]()

    required public init(tag: String?) {
        super.init(tag: tag)
    }
}
