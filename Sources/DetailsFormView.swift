//
//  DetailsFormView.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

open class DetailsFormView: UIViewController, DetailsForm {

    dynamic open var hasPreviousRecord: Bool = false
    dynamic open var hasNextRecord: Bool = false

    // MARK: override
    open override func viewDidLoad() {
        super.viewDidLoad()

        installSwipeGestureRecognizer()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkActions()
    }

    /*
    open func installNavigationItems() {
        // Configure  table bar, COULD DO : do it automatically if no buttons already in bar, if boolean set ?
        /*self.navigationItem.rightBarButtonItems = [,
         UIBarButtonItem(image: UIImage(named: "next")!, style: .plain, target: self, action: #selector(DetailsFormViewController.nextRecord(_:)))
         UIBarButtonItem(image: UIImage(named: "previous")!, style: .plain, target: self, action: #selector(DetailsFormViewController.previousRecord(_:)))
         ]*/
    }*/

    // MARK: IBAction

    @IBAction open func previousRecord(_ sender: Any!) {
         // TODO animation, like transitioning on self...
        // could use segue
         self.previousRecord()
    }

    @IBAction open func nextRecord(_ sender: Any!) {
        self.nextRecord()
        checkActions()
    }

    @IBAction func deleteRecord(_ sender: Any!) {
        self.deleteRecord()
        checkActions()
    }

    // MAR: Swipe gesture

    fileprivate var swipeLeft: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipeLeft(_:)))
    fileprivate var swipRight: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipeRight(_:)))

    @IBInspectable open var hasSwipeGestureRecognizer: Bool = true {
        didSet {
            installSwipeGestureRecognizer()
        }
    }

    func installSwipeGestureRecognizer() {
        guard isViewLoaded else {
            return
        }
        if hasSwipeGestureRecognizer {
            swipeLeft.direction = .left
            self.view.addGestureRecognizer(swipeLeft)

            swipRight.direction = .right
            self.view.addGestureRecognizer(swipRight)
        } else {
            self.view.removeGestureRecognizer(swipeLeft)
            self.view.removeGestureRecognizer(swipRight)
        }
    }
    open func swipeLeft(_ sender: UISwipeGestureRecognizer!) {
        self.previousRecord(sender)
    }
    open func swipeRight(_ sender: UISwipeGestureRecognizer!) {
        self.nextRecord(sender)
    }

}
