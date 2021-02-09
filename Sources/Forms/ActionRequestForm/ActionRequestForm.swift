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

public struct ActionRequestFormUI: View {
    @EnvironmentObject public var instance: ActionManager
    public var requests: [ActionRequest]
    var hasDetailLink = false
    var actionContext: ActionContext?

    enum SectionCase: String, Identifiable, CaseIterable {
        case pending, history
        var id: String { return rawValue } // swiftlint:disable:this identifier_name
    }
    var sections: [SectionCase] = SectionCase.allCases

    func getRequests(for sectionCase: SectionCase) -> [ActionRequest] {
        var requests: [ActionRequest]
        switch sectionCase {
        case .pending:
            requests = instance.requests.filter({ !$0.isCompleted }).sorted(by: { $0.creationDate > $1.creationDate })
        case .history:
            requests = instance.requests.filter({ $0.isCompleted }).sorted(by: { $0.creationDate > $1.creationDate })
        }
        if let actionContext = actionContext?.actionContextParameters() {
            requests = requests .filter {
                $0.contextParameters?[ActionParametersKey.table] as? String == actionContext[ActionParametersKey.table] as? String
                    && $0.contextParameters?[ActionParametersKey.record] as? [String: String] == actionContext[ActionParametersKey.record] as? [String: String]
                    && $0.contextParameters?[ActionParametersKey.record] as? [String: Int] == actionContext[ActionParametersKey.record] as? [String: Int]
            }
        }
        return requests.sorted(by: { $0.creationDate > $1.creationDate })
    }

    func hasRequests(for sectionCase: SectionCase) -> Bool {
        switch sectionCase {
        case .pending:
            return instance.requests.contains(where: { !$0.isCompleted })
        case .history:
            return instance.requests.contains(where: { $0.isCompleted })
        }
    }

    @ViewBuilder func footer(for sectionCase: SectionCase) -> some View {
        switch sectionCase {
        case .pending:
            Text(instance.isSuspended ? "🔴 Server is not accessible": "🟢 Server is online").onTapGesture(perform: {
                ServerStatusManager.instance.checkStatus()
            })
        case .history:
            Spacer()
        }
    }

    public var body: some View {
        List {
            ForEach(sections) { section in
                Section(header: Text(section.rawValue), footer: footer(for: section)) {
                    if hasRequests(for: section) {
                        ForEach(getRequests(for: section), id: \.id) { request in
                            switch section {
                            case .pending:
                                if hasDetailLink {
                                    NavigationLink(destination: ActionRequestDetail(request: request)) {
                                        ActionRequestRow(request: request)
                                    }
                                } else {
                                    ActionRequestRow(request: request)
                                }
                            case .history:
                                ActionRequestRow(request: request)
                            }
                        }
                    } else {
                        switch section {
                        case .pending:
                            Text("0 draft")
                                .foregroundColor(.secondary)
                        case .history:
                            Text("Nothing has happened yet") // "0 item"
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
    }
}

struct ActionRequestFormUI_Previews: PreviewProvider {
    static var previews: some View {
        ActionRequestFormUI(requests: ActionRequest.examples).environmentObject(ActionManager.instance)
    }
}
