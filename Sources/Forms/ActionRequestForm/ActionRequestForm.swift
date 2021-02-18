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
    var hasDetailLink = true
    var actionContext: ActionContext?
    @State private var editMode = EditMode.inactive

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
            requests = instance.requests.filter({ $0.state == .finished }).sorted(by: { $0.creationDate > $1.creationDate })
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
        // TODO takeinto account also actionContext
        switch sectionCase {
        case .pending:
            return instance.requests.contains(where: { !$0.isCompleted })
        case .history:
            return instance.requests.contains(where: { $0.state == .finished })
        }
    }

    @ViewBuilder func header(for sectionCase: SectionCase) -> some View {
        switch sectionCase {
        case .pending:
            Text(instance.isServerAccessible ? "🟢 Server is online": "🔴 Server is not accessible")
                .onTapGesture(perform: {
                    ServerStatusManager.instance.checkStatus()
                })
        case .history:
            Text(sectionCase.rawValue)
        }
    }

    @ViewBuilder func footer(for sectionCase: SectionCase) -> some View {
        switch sectionCase {
        case .pending:
            Button(action: {
                instance.pause.toggle()
            }, label: {
                Image(systemName: instance.pause ? "play": "pause")
                    .padding(5)
                    .foregroundColor(Color("ForegroundColor"))
                    .background(Color("BackgroundColor"))
                    .cornerRadius(5)
            })
        case .history:
            Spacer()
        }
    }

    public var body: some View {
        List {
            ForEach(sections) { section in
                Section(header: header(for: section), footer: footer(for: section)) {

                    switch section {
                    case .pending:
                        if true /* hasRequests(for: section) */{
                            let requests = getRequests(for: section)
                            ForEach(requests, id: \.id) { request in
                                if hasDetailLink && !request.action.parameters.isEmpty {
                                    ActionRequestEditableRow(request: request, instance: instance)
                                } else {
                                    ActionRequestRow(request: request)
                                }
                            }
                            .onDelete { index in
                                onDelete(index, requests)
                            }
                            .environment(\.editMode, $editMode)
                        } /*else {
                     Text("0 draft")
                     .foregroundColor(.secondary)
                     }*/
                    case .history:
                        if hasRequests(for: section) {
                            ForEach(getRequests(for: section), id: \.id) { request in
                                ActionRequestRow(request: request)
                            }
                        } else {
                            Text("Nothing has happened yet") // "0 item"
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }.toolbar {
            if hasRequests(for: .pending) {
                EditButton()
            }
        }
        .onPushToRefresh(customize: { $0.tintColor = UIColor.foreground }, refreshing: { refreshControl in
            DispatchQueue.main.after(0.2) {
                ServerStatusManager.instance.checkStatus()
                refreshControl.endRefreshing()
            }
        })
        .listStyle(GroupedListStyle())

    }
    @State private var offset = CGSize.zero
    private func onDelete(_ indexSet: IndexSet, _ requests: [ActionRequest]) {
        let pendingRequest = requests // getRequests(for: .pending)
        // pendingRequest.remove(atOffsets: offsets)

        for index in indexSet {
            if let request = pendingRequest[safe: index] {
                instance.remove(request)
            }
        }
    }
}

struct ActionRequestEditableRow: View {
    @State var showModal = false
    @State var request: ActionRequest
    @ObservedObject public var instance: ActionManager

    public var body: some View {
        let actionParametersForm = ActionFormViewControllerUI(request: request)
        NavigationLink(destination: actionParametersForm.toolbar {
            Button("Done") {
                // actionParametersForm.done {
                showModal.toggle()
                // }
            }
        }, isActive: $showModal) {
            ActionRequestRow(request: request)
        }
    }
}

struct ActionRequestFormUI_Previews: PreviewProvider {
    static var previews: some View {
        ActionRequestFormUI(requests: ActionRequest.examples).environmentObject(ActionManager.instance)
    }
}
