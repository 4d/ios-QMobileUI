//
//  UIAlertController+ActionParametersUI.swift
//  QMobileUI
//
//  Created by Eric Marchand on 24/05/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import UIKit
import QMobileAPI

extension UIAlertController: ActionParametersUI {

    /// Build an action controller for one field
    static func build(_ action: Action, _ actionUI: ActionUI, _ context: ActionContext, _ completionHandler: @escaping CompletionHandler) {
        guard  let parameters = action.parameters, let parameter = parameters.first else {
            completionHandler(.failure(.noParameters))
            return
        }

        let alertController = UIAlertController(title: parameter.label ?? parameter.name, message: nil, preferredStyle: .actionSheet)

        var actionParametersValue: [String: Any] = [:]

        switch parameter.type {
        case .string, .text:
            alertController.addOneTextField { textField in
                textField.left(image: UIImage(named: "next"), color: .black)
                textField.leftViewPadding = 12

                textField.becomeFirstResponder()

                textField.borderWidth = 1
                textField.borderColor = UIColor.lightGray.withAlphaComponent(0.5)
                textField.layer.cornerRadius = 8
                textField.backgroundColor = nil
                textField.textColor = .black

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
            alertController.message = "Select a date"
            alertController.addDatePicker(mode: .date, date: Date()) { date in
                actionParametersValue[parameter.name] = date
            }
        case .duration, .time:
            alertController.addDatePicker(mode: .time, date: Date()) { date in
                actionParametersValue[parameter.name] = date
            }
        case .picture, .image:
            // XXX list of images from library?
            alertController.addImagePicker(flow: .vertical, paging: true, images: [])
        case .integer, .number, .real:
            let numberValues: [Int] = (1...100).map { $0 }
            let pickerViewValues: [[String]] = [numberValues.map { $0.description }]
            alertController.addPickerView(values: pickerViewValues) { (_, _, index, _) in
                actionParametersValue[parameter.name] = numberValues[index.row]
            }
        default:
            break // XXX show notingg
        }

        let validateAction = UIAlertAction(title: "Done", style: .default) { _ in
            completionHandler(.success((action, actionUI, context, actionParametersValue)))
        }
        alertController.addAction(validateAction)

        _ = alertController.checkPopUp(actionUI)
        alertController.show()
    }

}
