//
//  ActionRequestForm.swift
//  QMobileUI
//
//  Created by phimage on 27/01/2021.
//  Copyright © 2021 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

import QMobileAPI

open class ActionRequestForm: UIHostingController<ActionRequestFormUI> {
}

public struct ActionRequestFormUI: View {
    @State public var requests: [ActionRequest]

    public var body: some View {
        NavigationView {
            VStack {
                List(requests, id: \.action.name) { request in

                    NavigationLink(destination: ActionRequestDetail(request: request)) {
                        ActionRequestRow(request: request)
                    }

                }
                /* List(requests, id: \.action.name) { request in

                 NavigationLink(destination: ActionRequestDetail(request: request)) {
                 ActionRequestRow(request: request)
                 }
                 
                 }*/
            }
        }.navigationTitle("Requests log")
    }
}

struct ActionRequestFormUI_Previews: PreviewProvider {
    static var previews: some View {
        ActionRequestFormUI(requests: [
            ActionRequest(action: Action(name: "addEmploye")),
            ActionRequest(action: Action(name: "deleteX"))
        ])
    }
}
