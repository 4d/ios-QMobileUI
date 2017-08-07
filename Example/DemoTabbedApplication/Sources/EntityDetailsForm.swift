//
//  DetailViewController\.swift
//  DemoTabbedApplication
//
//  Created by Eric Marchand on 16/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit
import QMobileUI
import IBAnimatable

class EntityDetailsFormTable: DetailsFormTable {

    var transitionType: TranstionOnSelf = .curl
    var transitionDuration: TimeInterval = 0.5

    override func onWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        self.navigationController?.setToolbarHidden(false, animated: animated)
    }

    @IBAction open override func previousRecord(_ sender: Any!) {
        transitionOnSelf(duration: transitionDuration, options: [transitionType.left]) {
            super.previousRecord(sender)
        }
    }

    @IBAction open override func nextRecord(_ sender: Any!) {
        transitionOnSelf(duration: transitionDuration, options: [transitionType.right]) {
            super.nextRecord(sender)
        }
    }

}

class EntityDetailsForm: DetailsFormBare {

    var transitionType: TranstionOnSelf = .flip
    var transitionDuration: TimeInterval = 0.5

    override func onWillAppear(_ animated: Bool) {

    }

    @IBAction open override func previousRecord(_ sender: Any!) {
        transitionOnSelf(duration: transitionDuration, options: [transitionType.left]) {
            super.previousRecord(sender)
        }

       /*let presenter = TransitionPresenterManager.shared.retrievePresenter(transitionAnimationType: .flip(from: .left))

        if let tran = AnimatorFactory.makeAnimator(transitionAnimationType: .flip(from: .left), transitionDuration: 0.5) {

        }
        */
    }

    @IBAction open override func nextRecord(_ sender: Any!) {
        transitionOnSelf(duration: transitionDuration, options: [transitionType.right]) {
              super.nextRecord(sender)
        }
    }

    func viewCenter(_ sender: Any) -> CGPoint? {
        if let view = sender as? UIView {
            return  view.center
        } else if let item = sender as? UIBarItem, let view = item.value(forKey: "view") as? UIView {
            return  view.center
        }
        return nil
    }
}

enum TranstionOnSelf {
    case flip, curl, flipVertical
}

extension TranstionOnSelf {
    var left: UIViewAnimationOptions {
        switch self {
        case .flip: return .transitionFlipFromLeft
        case .curl: return .transitionCurlUp
        case .flipVertical: return .transitionFlipFromTop
        }
    }
    var right: UIViewAnimationOptions {
        switch self {
        case .flip: return .transitionFlipFromRight
        case .curl: return .transitionCurlDown
        case .flipVertical: return .transitionFlipFromBottom
        }
    }
}
