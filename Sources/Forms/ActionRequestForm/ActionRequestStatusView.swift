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
        switch request.state {
        case .executing:
            ZStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                Text(" ") // to fix padding...
            }
        case .ready:
            Image(systemName: "mail.stack")
                .foregroundColor(.primary)
        default:
            Text(request.statusImage(color: true))
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
            ActionRequestStatusView(request: ActionRequest.examples[4])

        }.previewLayout(.fixed(width: 32, height: 32))
    }
}
