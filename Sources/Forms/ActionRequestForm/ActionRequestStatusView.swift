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
        HStack(alignment: .top) {
            switch request.state {
            case .executing, .ready:
                ZStack {
                    // Circle().stroke(Color.primary).frame(maxWidth: 20)
                    Ellipsis(scale: .small, color: Color.primary).frame(maxWidth: 20)
                }
            default:
                Text(request.statusImage(color: true))
            }
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
