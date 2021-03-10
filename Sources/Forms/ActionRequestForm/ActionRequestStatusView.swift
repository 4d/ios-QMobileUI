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
                    Circle().stroke(Color.primary)
                    Ellipsis(scale: .small, color: Color.primary)
                }.frame(maxWidth: 20, maxHeight: 20)
            case .completed:
                switch request.result! {
                case .success(let value):
                    if value.success {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 22, weight: .regular))
                    } else {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 22, weight: .regular))
                    }
                case .failure:
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 22, weight: .regular))
                }
            case .cancelled:
                Image(systemName: "multiply.circle.fill").foregroundColor(.blue).frame(maxWidth: 24)
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
