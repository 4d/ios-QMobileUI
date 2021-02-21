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
        return ActionFormViewController(builder: self.request.builder)
    }

    func updateUIViewController(_ uiViewController: ActionFormViewController, context: UIViewControllerRepresentableContext<ActionFormViewControllerUI>) {
        if action {
            self.action = false
            uiViewController.externalDone { (result) in
                self.result = result
            }
        }

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
