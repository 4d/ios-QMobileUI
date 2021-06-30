//
//  UIAlertController+ActionParametersUI.swift
//  QMobileUI
//
//  Created by Eric Marchand on 24/05/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import UIKit
import QMobileAPI
import Combine

extension UIAlertController: ActionParametersUI {

    /// Build an action controller for one field
    static func build(_ action: Action, _ actionUI: ActionUI, _ context: ActionContext, _ actionExecutor: ActionExecutor) -> ActionParametersUIControl? { // swiftlint:disable:this function_body_length
        guard let parameters = action.parameters, let parameter = parameters.first else {
            return nil
        }
        guard parameters.count == 1 else {
            return nil // if two field ignore (maybe could support two text field)
        }

        let alertController = UIAlertController(title: parameter.preferredLongLabelMandatory, message: nil, preferredStyle: .actionSheet)

        var actionParametersValue: [String: Any] = [:]

        if let format = parameter.format {
            switch format {
            case .email, .url, .phone:
                break
            default:
                return nil // no managed yet
            }
        }
        if parameter.choiceList != nil {
            return nil
        }
        switch parameter.type {
        case .string, .text:
            alertController.addOneTextField { textField in
                textField.left(image: UIImage(named: "next"), color: .label)
                textField.leftViewPadding = 12

                textField.becomeFirstResponder()

                textField.borderWidth = 1
                textField.borderColor = ColorCompatibility.systemGray2.withAlphaComponent(0.5)
                textField.layer.cornerRadius = 8
                textField.backgroundColor = nil
                textField.textColor = .label

                textField.keyboardAppearance = .default
                textField.returnKeyType = .done

                textField.from(actionParameter: parameter, context: context)

                // textField.isSecureTextEntry = true
                textField.action { textField in
                    logger.debug("textField: \(String(describing: textField.text))")
                    actionParametersValue[parameter.name] = textField.text
                }
            }
        case .date:
            alertController.message = nil
            var date = Date()
            if let defaultValue = parameter.defaultValue(with: context) as? Date {
                date = defaultValue
            }
            alertController.addDatePicker(mode: .date, date: date) { date in
                actionParametersValue[parameter.name] = date
            }
        case .time:
            var date = Date(timeInterval: 0)
            if let defaultValue = parameter.defaultValue(with: context) as? Date {
                date = defaultValue
            }
            alertController.addDatePicker(mode: .time, date: date) { date in
                actionParametersValue[parameter.name] = date
            }
        /*case .picture, .image:
            // XXX list of images from library?
            alertController.addImagePicker(flow: .vertical, paging: true, images: [])*/
        /*case .integer, .number, .real:
            let numberValues: [Int] = (1...100).map { $0 }
            let pickerViewValues: [[String]] = [numberValues.map { $0.description }]
            alertController.addPickerView(values: pickerViewValues) { (_, _, index, _) in
                actionParametersValue[parameter.name] = numberValues[index.row]
            }*/
        default:
          return nil
        }

        let validateAction = UIAlertAction(title: "Done", style: .default) { _ in
            let builder = ActionParametersUIBuilder(action, actionUI, context, actionExecutor)
            _ = builder.executeAction(with: actionParametersValue, waitUI: Just(()).eraseToAnyPublisher())
        }
        alertController.addAction(validateAction)
        alertController.addAction(alertController.dismissAction())

        _ = alertController.checkPopUp(actionUI)
        return alertController
    }

}
