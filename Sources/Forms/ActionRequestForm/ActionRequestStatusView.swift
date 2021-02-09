//
//  ActionRequestStatusView.swift
//  QMobileUI
//
//  Created by emarchand on 05/02/2021.
//  Copyright © 2021 Eric Marchand. All rights reserved.
//

import SwiftUI
import QMobileAPI

struct ActionRequestStatusView: View {
    @State var request: ActionRequest
    var body: some View {
        if request.state == .executing {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
        } else if request.state == .ready {
            Image(systemName: "mail.stack")
                .foregroundColor(.primary)
        } else {
            Text(request.statusImage)
        }
    }
}

struct ActionRequestStatusView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ActionRequestStatusView(request: ActionRequest.examples[0])
            ActionRequestStatusView(request: ActionRequest.examples[1])
            ActionRequestStatusView(request: ActionRequest.examples[2])
            ActionRequestStatusView(request: ActionRequest.examples[3])

        }.previewLayout(.fixed(width: 32, height: 32))
    }
}

extension ActionRequest {

    var statusImage: String {
        switch state {
        case .cancelled:
            return "🚫"
        case .executing:
            return "-" // replaced by spinner
        /*case .pending:
            return "⏸"*/
        case .ready:
            return "🆕"
        case .finished:
            switch result! {
            case .success(let value):
                if value.success {
                    return "🟢"
                } else {
                    return "🟠"
                }
            case .failure:
                return "🔴"
            }
        }
    }
}
