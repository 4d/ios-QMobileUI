//
//  DetailsFormBare.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

open class DetailsFormBare: UIViewController, DetailsForm {

    dynamic open var hasPreviousRecord: Bool = false
    dynamic open var hasNextRecord: Bool = false

    // MARK: override
    final public override func viewDidLoad() {
        super.viewDidLoad()
        onLoad()
    }

    final public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkActions()
        onWillAppear(animated)
    }

    final public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        installSwipeGestureRecognizer()
        onDidAppear(animated)
    }

    final public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onWillDisappear(animated)
    }

    final public override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onDidDisappear(animated)
    }

    // MARK: Events
    /// Called after the view has been loaded. Default does nothing
    open func onLoad() {}
    /// Called when the view is about to made visible. Default does nothing
    open func onWillAppear(_ animated: Bool) {}
    /// Called when the view has been fully transitioned onto the screen. Default does nothing
    open func onDidAppear(_ animated: Bool) {}
    /// Called when the view is dismissed, covered or otherwise hidden. Default does nothing
    open func onWillDisappear(_ animated: Bool) {}
    /// Called after the view was dismissed, covered or otherwise hidden. Default does nothing
    open func onDidDisappear(_ animated: Bool) {}

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
        // could use segue do do that but it will put more info into storyboard and navigation will be confusing
        self.previousRecord()
        self.checkNavigationBar()
    }

    @IBAction open func nextRecord(_ sender: Any!) {
        self.nextRecord()
        checkNavigationBar()
    }

    @IBAction func deleteRecord(_ sender: Any!) {
        self.deleteRecord()
        checkNavigationBar()
        // XXX DELETE go to previous or next record? keep current index? if no more records dismiss view
    }

    func checkNavigationBar() {
        checkActions()
        self.navigationController?.navigationBar.bindTo.updateView()
    }

    // MARK: Swipe gesture

    fileprivate var swipes: [UISwipeGestureRecognizerDirection: UISwipeGestureRecognizer] = [:]

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
            for direction in UISwipeGestureRecognizerDirection.allArray {
                let recognizer =  UISwipeGestureRecognizer(target: self, action: #selector(onSwipe(_:)))
                recognizer.direction = direction
                swipes[direction] = recognizer
                addGestureRecognizer(recognizer)
            }
        } else {
            for (_, recognizer) in swipes {
                removeGestureRecognizer(recognizer)
            }
            swipes.removeAll()
        }
    }

    /// Receive swipe action and do action according to direction
    open func onSwipe(_ sender: UISwipeGestureRecognizer!) {
        if sender.direction.contains(.left) {
            self.nextRecord(sender)
        } else if sender.direction.contains(.right) {
            self.previousRecord(sender)
        }
    }

}
