//
//  MultipleImagePickerController.swift
//  QMobileUI
//
//  Created by Eric Marchand on 09/12/2019.
//  Copyright © 2019 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit
import Eureka

/// Selector Controller used to pick an image
public class MultipleImagePickerController: UIImagePickerController, TypedRowControllerType, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var count = 0

    /// The row that pushed or presented this controller
    public var row: RowOf<[UIImage]>!

    /// A closure to be called when the controller disappears.
    public var onDismissCallback: ((UIViewController) -> Void)?

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }

    open func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage {
            if row.value == nil {
                row.value = []
            }
            row.value?.append(image)
            (row as? MultipleImageRow)?.imageURLs.reserveCapacity(count)
            (row as? MultipleImageRow)?.imageURLs[count] = info[.imageURL] as? URL
            count += 1
        }
        onDismissCallback?(self)
    }

    open func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        onDismissCallback?(self)
    }
}
