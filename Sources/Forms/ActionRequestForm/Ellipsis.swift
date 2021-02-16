//
//  Ellipsis.swift
//  QMobileUI
//
//  Created by emarchand on 11/02/2021.
//  Copyright © 2021 Eric Marchand. All rights reserved.
//

import Foundation
import SwiftUI

struct Ellipsis: View {

    @State private var shouldAnimate = false

    var scale: Image.Scale
    var color: Color
    init(scale: Image.Scale, color: Color) {
        self.scale = scale
        self.color = color
    }

    var body: some View {
        HStack(alignment: .center, spacing: scale.spacing) {
            Circle().fill(color).frame(width: scale.pointSize, height: scale.pointSize)
                // .scaleEffect(shouldAnimate ? 0.5 : 1.0)
                .opacity(shouldAnimate ? 0.0 : 1.0)
                .animation(Animation.easeInOut(duration: 1).repeatForever())
            Circle().fill(color).frame(width: scale.pointSize, height: scale.pointSize)
                // .scaleEffect(shouldAnimate ? 0.5 : 1.0)
                .opacity(shouldAnimate ? 0.0 : 1.0)
                .animation(Animation.easeInOut(duration: 1).repeatForever().delay(0.3))
            Circle().fill(color).frame(width: scale.pointSize, height: scale.pointSize)
                // .scaleEffect(shouldAnimate ? 0.5 : 1.0)
                .opacity(shouldAnimate ? 0.0 : 1.0)
                .animation(Animation.easeInOut(duration: 1).repeatForever().delay(0.6))
        }.padding(1).onAppear {
            self.shouldAnimate = true
        }
    }
}

fileprivate extension Image.Scale {
    var pointSize: CGFloat {
        switch self {
        case .large:
            return 4
        case .medium:
            return 10 / 3
        case .small:
            return 2.5
        @unknown default:
            fatalError()
        }
    }

    var spacing: CGFloat {
        switch self {
        case .large:
            return 3.7
        case .medium:
            return 3
        case .small:
            return 2.3
        @unknown default:
            fatalError()
        }
    }
}
