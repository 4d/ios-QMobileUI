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

    /// the requet
    var request: ActionRequest
    var listener: ((Result<ActionParameters, ActionFormError>) -> Void)

    init(request: ActionRequest, listener: @escaping ((Result<ActionParameters, ActionFormError>) -> Void)) {
        self.request = request
        self.listener = listener
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActionFormViewControllerUI>) -> ActionFormViewController {
        let controller = ActionFormViewController(builder: self.request.builder)
        controller.listener = listener
        return controller
    }

    func updateUIViewController(_ uiViewController: ActionFormViewController, context: UIViewControllerRepresentableContext<ActionFormViewControllerUI>) {}
}

struct ActionFormViewControllerUI_Previews: PreviewProvider {
    static var previews: some View {
        ActionFormViewControllerUI(request: ActionRequest.examples[1], listener: { _ in })
    }
}

extension ActionRequest {
    var builder: ActionParametersUIBuilder {
        return ActionParametersUIBuilder(self.action, BackgroundActionUI(), self, ActionManager.instance)
    }
}
