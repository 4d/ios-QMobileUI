//
//  DetailsFormTable.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

/// A detail form based on apple `UITableViewController` which provide an `UITableView`.
open class DetailsFormTable: UITableViewController, DetailsForm {

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

    // MARK: TableView
    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Install data into each table cell
        let staticCell = super.tableView(tableView, cellForRowAt: indexPath)
        staticCell.tableView = self.tableView
        staticCell.record = self.tableView.record
        staticCell.table = self.tableView.table

        return staticCell
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

    // MARK: IBAction

    @IBAction open func previousRecord(_ sender: Any!) {
        self.previousRecord()
        checkNavigationBar()
        checkTable()
    }

    @IBAction open func nextRecord(_ sender: Any!) {
        self.nextRecord()
        checkNavigationBar()
        checkTable()
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
        checkNavigationBar()
        checkTable()
        // XXX DELETE go to previous or next record? keep current index? if no more records dismiss view

    }

    func checkNavigationBar() {
        checkActions()
        self.navigationController?.navigationBar.bindTo.updateView()
    }

    func checkTable() {
        // updateView on root don't affect all cell...
        // do reload data will work on this static table

        self.tableView?.reloadData()

        /*
        // we could also browse all cells and call update
        for cell in self.cells {
            cell.bindTo.updateView()
        }
        */
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
    @objc open func onSwipe(_ sender: UISwipeGestureRecognizer!) {
        if sender.direction.contains(.left) {
            self.nextRecord(sender)
        } else if sender.direction.contains(.right) {
            self.previousRecord(sender)
        }
    }

}
