//
//  DetailsFormTable.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

open class DetailsFormTable: UITableViewController, DetailsForm {

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

    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Install data into each table cell
        let staticCell = super.tableView(tableView, cellForRowAt: indexPath)
        staticCell.tableView = self.tableView
        staticCell.record = self.tableView.record
        staticCell.table = self.tableView.table

        return staticCell
    }

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

    open func installSwipeGestureRecognizer() {
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
