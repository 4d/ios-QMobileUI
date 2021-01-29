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
    @State var request: ActionRequest

    public var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(request.action.preferredShortLabel).font(.headline)
                Spacer()
                Text(request.statusText).foregroundColor(.secondary).font(.subheadline)
            }
            Spacer()
            Text(request.statusImage)
        }.padding()
    }
}

struct ActionRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ActionRequestRow(request: ActionRequest(action: Action(name: "addEmploye")))
            ActionRequestRow(request: ActionRequest(action: Action(name: "deleteX"), result: .success(.emptySuccess)))
            ActionRequestRow(request: ActionRequest(action: Action(name: "deleteR"), result: .success(.emptyFailure)))
        }.previewLayout(.fixed(width: 300, height: 70))
    }
}

extension ActionRequest {

    var statusImage: String {
        switch state {
        case .cancelled:
            return "🚫"
        case .executing:
            return "⌛️"
        case .pending:
            return "⏸"
        case .ready:
            return "🚀"
        case .finished:
            switch result! {
            case .success(let value):
                if value.success {
                    return "✅"
                } else {
                    return "✴️"
                }
            case .failure:
                return "❗️"
            }
        }
    }
}
