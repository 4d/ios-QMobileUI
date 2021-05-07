//
//  ActionFormViewControllerUI.swift
//  QMobileUI
//
//  Created by emarchand on 11/02/2021.
//  Copyright © 2021 Eric Marchand. All rights reserved.
//

import Foundation
import SwiftUI
import QMobileAPI

struct ActionFormViewControllerUI: UIViewControllerRepresentable {

    typealias UIViewControllerType = ActionFormViewController

    /// the request
    var request: ActionRequest
    @Binding var action: Bool
    @Binding var result: Result<ActionParameters, ActionFormError>?

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActionFormViewControllerUI>) -> ActionFormViewController {
        let form = ActionFormViewController(builder: self.request.builder)
        form.hasValidateForm = request.result != nil // because if we have a result, its means that we have already validated the form
        return form
    }

    func updateUIViewController(_ form: ActionFormViewController, context: UIViewControllerRepresentableContext<ActionFormViewControllerUI>) {
        if action {
            self.action = false
            form.externalDone { (result) in
                self.result = result
            }
        }
        if let error = request.formError {
            _ = form.fillErrors(error)
        }
    }
}

extension ActionRequest {
    /// A potential error to display in form if there is already a result
    /// It could be message from server by field in `errors` key as collection
    var formError: ActionFormError? {
        if let result = self.result, case .success(let actionResult) = result, let errors = actionResult.errors {
            return ActionFormError.components(errors)
        }
        return nil
    }

   /* /// Return `true` if there is in `result` some error to display in form.
    var hasFormError: Bool {
        if let result = self.result, case .success(let actionResult) = result {
            return actionResult.errors != nil
        }
        return false
    }*/

    /// Return `true` if action execution success but server reject it with success = false. Maybe we could retry it with different parameter.
    var couldEditDoneAction: Bool {
        if let result = self.result, case .success(let actionResult) = result {
            return !actionResult.success
        }
        return false
    }
}

struct ActionFormViewControllerUI_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper.init(false, nil) {
            ActionFormViewControllerUI(request: ActionRequest.examples[1], action: $0, result: $1)
        }
    }
}

extension ActionRequest {
    var builder: ActionParametersUIBuilder {
        return ActionParametersUIBuilder(self.action, BackgroundActionUI(), self, ActionManager.instance)
    }
}
struct StatefulPreviewWrapper<Value, Value2, Content: View>: View {
    @State var value: Value
    @State var value2: Value2
    var content: (Binding<Value>, Binding<Value2>) -> Content

    var body: some View {
        content($value, $value2)
    }

    init(_ value: Value, _ value2: Value2, content: @escaping (Binding<Value>, Binding<Value2>) -> Content) {
        self._value = State(wrappedValue: value)
        self._value2 = State(wrappedValue: value2)
        self.content = content
    }
}
