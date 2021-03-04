//
//  ActionRequestRow.swift
//  QMobileUI
//
//  Created by phimage on 27/01/2021.
//  Copyright © 2021 Eric Marchand. All rights reserved.
//

import Foundation
import SwiftUI

import QMobileAPI // action model

public struct ActionRequestRow: View {
    let request: ActionRequest

    public var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top, spacing: 2) {
                VStack(alignment: .leading) {
                    ActionRequestStatusView(request: request)
                        .frame(maxWidth: 28, minHeight: 28, maxHeight: 28, alignment: .topLeading)
                    Spacer()
                    Spacer()
                }
                VStack(alignment: .leading) {
                    Text(request.action.preferredLongLabel)
                        .font(.headline)
                        .lineLimit(1)
                    Text(request.summary)
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                Spacer()
                Spacer()
            }
            MetadataView(request: request)
                .font(.caption)
                .opacity(0.75)
        }// .padding()
    }
}

struct ActionRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ActionRequestRow(request: ActionRequest.examples[0])
            ActionRequestRow(request: ActionRequest.examples[1])
            ActionRequestRow(request: ActionRequest.examples[2])
            ActionRequestRow(request: ActionRequest.examples[3])
        }.previewLayout(.fixed(width: 300, height: 70))
    }
}

extension ActionRequest {

    static var examplesContext: [ActionParameters] {
        return [
            [ActionParametersKey.table: "myTable"],
            [ActionParametersKey.table: "myTable", ActionParametersKey.record: [ActionParametersKey.primaryKey: "MYPRIMARYKEY"]]
        ]
    }

    static var examples: [ActionRequest] {
        return [
            ActionRequest(action: Action.examples[0], contextParameters: ActionRequest.examplesContext[0], id: ActionRequest.generateID(Action.examples[0]), state: .ready),
            ActionRequest(action: Action.examples[1], contextParameters: ActionRequest.examplesContext[1], id: ActionRequest.generateID(Action.examples[1]), state: .executing),
            ActionRequest(action: Action.examples[1], id: ActionRequest.generateID(Action.examples[1]), state: .finished, result: .success(.emptySuccess)),
            ActionRequest(action: Action.examples[2], id: ActionRequest.generateID(Action.examples[2]), state: .finished, result: .success(.emptyFailure)),
            ActionRequest(action: Action.examples[3], id: ActionRequest.generateID(Action.examples[3]), state: .finished, result: .failure(APIError.request(NSError(domain: "test", code: 1, userInfo: [:]))))
        ]
    }

}
extension Action {

    static var examples: [Action] {
        return [
            Action(name: "add Employe"),
            Action(name: "delete X"),
            Action(name: "delete Y"),
            Action(name: "modify X")
        ]
    }

}
