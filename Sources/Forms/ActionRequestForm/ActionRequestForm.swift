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
    // action manager to use
    @EnvironmentObject public var instance: ActionManager // CLEAN rename instance to actionManager everywhere

    // context could be table or record
    public var actionContext: ActionContext?

    // allow to edit ie. delete
    @State private var editMode = EditMode.inactive

    // some feature flags
    var hasDetailLink = true
    #if DEBUG
    var hasPauseButton = false
    #else
    var hasPauseButton = false
    #endif

    enum SectionCase: String, Identifiable, CaseIterable {
        case pending, completed
        var id: String { return rawValue } // swiftlint:disable:this identifier_name
    }
    var sections: [SectionCase] {
        return SectionCase.allCases.filter({ ($0 == .completed) || hasRequests(for: $0)   })
    }

    func getRequests(for sectionCase: SectionCase) -> [ActionRequest] {
        var requests: [ActionRequest]
        switch sectionCase {
        case .pending:
            requests = instance.requests.filter({ !$0.state.isFinal }).sorted(by: { $0.creationDate > $1.creationDate })
        case .completed:
            requests = instance.requests.filter({ $0.state.isCompleted }).sorted(by: { $0.creationDate > $1.creationDate })
        }
        if let actionContext = actionContext {
            requests = actionContext.filter(requests)
        }
        return requests.sorted(by: { $0.creationDate > $1.creationDate })
    }

    func hasRequests(for sectionCase: SectionCase) -> Bool {
        var requests = instance.requests
        if let actionContext = actionContext {
            requests = actionContext.filter(requests)
        }
        switch sectionCase {
        case .pending:
            return requests.contains(where: { !$0.state.isFinal })
        case .completed:
            return requests.contains(where: { $0.state.isCompleted })
        }
    }

    @ViewBuilder func header(for sectionCase: SectionCase) -> some View {
        switch sectionCase {
        case .pending:
            HStack {
                Text(sectionCase.rawValue)
                #if DEBUG
                    .onTapGesture(perform: {
                        ActionManager.instance.debugInfo()
                    })
                #endif
                Text(instance.isServerAccessible ? " (Server is online)": " (Server is not accessible)")
                    .onTapGesture(perform: {
                        ServerStatusManager.instance.checkStatus()
                    })
                    .textCase(nil)

            }
        case .completed:
            Text(sectionCase.rawValue)
        }
    }

    @ViewBuilder func footer(for sectionCase: SectionCase) -> some View {
        EmptyView()
    }

    public var body: some View {
        List {
            ForEach(sections) { section in
                Section(header: header(for: section), footer: footer(for: section)) {

                    switch section {
                    case .pending:
                        if true /* hasRequests(for: section) */{
                            let requests = getRequests(for: section)
                            ForEach(requests, id: \.uniqueID) { request in
                                if hasDetailLink && !request.action.parameters.isEmpty {
                                    ActionRequestEditableRow(request: request, actionManager: instance, shortTitle: actionContext != nil)
                                } else {
                                    ActionRequestRow(request: request, actionManager: instance, shortTitle: actionContext != nil)
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
                    case .completed:
                        if hasRequests(for: section) {
                            ForEach(getRequests(for: section), id: \.uniqueID) { request in
                                if  instance.editRejectedAction  && !request.action.parameters.isEmpty && request.couldEditDoneAction {
                                    ActionRequestEditableRow(request: request, actionManager: instance, shortTitle: actionContext != nil)
                                } else {
                                    ActionRequestRow(request: request, actionManager: instance, shortTitle: actionContext != nil)
                                }
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
                ActionManager.instance.willRefresh()
                refreshControl.endRefreshing()
            }
        })
        .listStyle(GroupedListStyle())
        .tabItem {  Label("Menu", systemImage: "list.dash") }
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

extension ActionRequest {
    // produce an unique id to identify request (even if id is empty)
    var uniqueID: String {
        return id + tableName + action.name + "\(creationDate)"
    }
}

struct ActionRequestEditableRow: View {
    @State var showModal = false
    @State var request: ActionRequest
    @ObservedObject public var actionManager: ActionManager
    @State var shortTitle: Bool

    @State var actionDone = false
    @State var result: Result<ActionParameters, ActionFormError>?
    @State var requestUpdated = false

    public var body: some View {
        let actionParametersForm = ActionFormViewControllerUI(
            request: request,
            action: $actionDone,
            result: $result.onChange(resultChanged))

        NavigationLink(destination: actionParametersForm.toolbar {
            Button(request.isFailure ? "Retry": "Done") {
                self.actionDone.toggle()
                self.requestUpdated = true
            }
        }, isActive: $showModal.animation()) {
            ActionRequestRow(request: request, actionManager: actionManager, shortTitle: shortTitle)
        }
        .onChange(of: showModal) { open in
            if !open && requestUpdated {
                actionManager.requestUpdated(request)
            }
            if !request.isFailure {
                actionManager.pause = open
            }
        }
    }

    func resultChanged(to result: Result<ActionParameters, ActionFormError>?) {

        // manage action request modification
        guard let result = result else {
            showModal.toggle() // dismiss
            logger.warning("No result from action parameters. Maybe no change")
            return
        }
        switch result {
        case .success(let values):
            // save new values to the request
            request.actionParameters = values
            request.encodeParameters()
            // we need here to to check if there is new image to upload to add operation on the queue
            // (because the operation of this request is already on the queue)
            // actionManager.requestUpdated(request)

            showModal.toggle() // dismiss
        case .failure(let error):
            logger.warning("Cannot update action request due to \(error)")
        }
    }
}

struct ActionRequestFormUI_Previews: PreviewProvider {
    static var previews: some View {
        ActionRequestFormUI().environmentObject(ActionManager.instance)
    }
}

extension ActionContext {

    /// Filter requests according to context.
    func filter(_ requests: [ActionRequest]) -> [ActionRequest] {
        if let actionContext = self.actionContextParameters() {
            let table = actionContext[ActionParametersKey.table] as? String
            let record = actionContext[ActionParametersKey.record] as? [String: String]
            let recordInt = actionContext[ActionParametersKey.record] as? [String: Int]
            let parent = (actionContext[ActionParametersKey.parent] as? [String: Any])?.mapValues { "\($0)" }

            var requests = requests.filter {
                $0.contextParameters?[ActionParametersKey.table] as? String == table
            }
            if parent != nil { // filter for relation
                requests = requests.filter {
                    (($0.contextParameters?[ActionParametersKey.parent] as? [String: Any])?.mapValues { "\($0)" })  == parent
                }
            } else if record != nil || recordInt != nil { // filter for one record
                requests = requests.filter {
                    $0.contextParameters?[ActionParametersKey.record] as? [String: String] == record
                        && $0.contextParameters?[ActionParametersKey.record] as? [String: Int] == recordInt
                }
            }
            return requests
        }
        return requests
    }

}

extension ActionRequest.State {

    var isCompleted: Bool {
        return self == .completed
    }
}
extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}
