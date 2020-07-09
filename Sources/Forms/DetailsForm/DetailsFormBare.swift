//
//  DetailsFormBare.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit
import Kingfisher

import QMobileDataStore

/// A detail form based on apple `UIViewController`, a simple empty view.
open class DetailsFormBare: UIViewController, DetailsForm {

    @objc dynamic open var hasPreviousRecord: Bool = false
    @objc dynamic open var hasNextRecord: Bool = false

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

    /// Called when the record change using standard actions (next, previous, last, first)
    open func onRecordChanged() {}

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
        // XXX here could add animation, like transitioning on self...
        // could use segue do do that but it will put more info into storyboard and navigation will be confusing
        self.previousRecord()
        self.checkNavigationBar()
    }

    @IBAction open func nextRecord(_ sender: Any!) {
        self.nextRecord()
        checkNavigationBar()
    }

    @IBAction open func lastRecord(_ sender: Any!) {
        self.lastRecord()
        checkNavigationBar()
    }

    @IBAction open func firstRecord(_ sender: Any!) {
        self.firstRecord()
        checkNavigationBar()
    }

    @IBAction func deleteRecord(_ sender: Any!) {
        self.deleteRecord()
        self.firstRecord() // XXX DELETE go to previous or next record? keep current index? if no more records dismiss view
        checkNavigationBar()
    }

    func checkNavigationBar() {
        checkActions()
        self.navigationController?.navigationBar.bindTo.updateView()
    }

    // MARK: Swipe gesture

    fileprivate var swipes: [UISwipeGestureRecognizer.Direction: UISwipeGestureRecognizer] = [:]

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
            for direction in UISwipeGestureRecognizer.Direction.allArray {
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
    @objc open func onSwipe(_ sender: UISwipeGestureRecognizer!) {
        if sender.direction.contains(.left) {
            self.nextRecord(sender)
        } else if sender.direction.contains(.right) {
            self.previousRecord(sender)
        }
    }

    // MARK: - segue

    /// Prepare transition by providing selected record to detail form.
    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination.firstController

        guard let relationInfoUI = sender as? RelationInfoUI else {
            logger.error("No information about the relation in UI (button or label in user defined attribute. From form \(self)")
            return
        }

        if let destination = destination as? ListForm { // 1 to Many relation
            ApplicationCoordinator.prepare(from: self, to: destination, relationInfoUI: relationInfoUI)
        } else if let destination = destination as? DetailsForm { // 1 to 1 relation
            ApplicationCoordinator.prepare(from: self, to: destination, relationInfoUI: relationInfoUI)
        }
        segue.fix()
    }

}
