//
//  ActionRequestDetail.swift
//  QMobileUI
//
//  Created by phimage on 27/01/2021.
//  Copyright © 2021 Eric Marchand. All rights reserved.
//

import Foundation
import SwiftUI

import QMobileAPI

public struct ActionRequestDetail: View {
    let request: ActionRequest
    @State var txt: String = ""

    public var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text(request.action.name)
                    .font(.title)

                HStack(alignment: .top) {
                    Text(request.id)
                        .font(.subheadline)
                    Spacer()
                    Text("\(request.creationDate)")
                        .font(.subheadline)
                    Spacer()
                    Text(txt)
                        .font(.subheadline)
                }
            }
            .padding()
            TextField("te", text: $txt)
            Spacer()
        }
    }
}

struct ActionDetail_Previews: PreviewProvider {
    static var previews: some View {
        ActionRequestDetail(request: ActionRequest.examples[0])
    }
}
