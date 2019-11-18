//
//  NSAttributedString+QMobile.swift
//  QMobileUI
//
//  Created by Eric Marchand on 23/07/2018.
//  Copyright © 2018 Eric Marchand. All rights reserved.
//

import Foundation
import UIKit

extension NSMutableAttributedString {

    func append(image: UIImage) {
        let image1Attachment = NSTextAttachment()
        image1Attachment.image = image
        self.append(NSAttributedString(attachment: image1Attachment))
    }

}
