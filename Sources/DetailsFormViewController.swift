//
//  DetailsFormViewController.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

extension UIViewController {
    
    @IBAction open func previousPage(_ sender: Any!) {
        self.dismiss(animated: true) { 

        }
    }

}

open class DetailsFormViewController: UIViewController, DetailsFormController {
    
    var swipeLeft: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(DetailsFormViewController.swipeLeft(_:)))
    var swipRight: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(DetailsFormViewController.swipeRight(_:)))
    
    open var hasPreviousRecord: Bool = false
    open var hasNextRecord: Bool = false
    
    @IBInspectable open var hasSwipeGestureRecognizer = true {
        didSet {
            installSwipeGestureRecognizer()
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()

        // Configure  table bar, COULD DO : do it automatically if no buttons already in bar, if boolean set ?
        /*self.navigationItem.rightBarButtonItems = [,
            UIBarButtonItem(image: UIImage(named: "next")!, style: .plain, target: self, action: #selector(DetailsFormViewController.nextRecord(_:)))
            UIBarButtonItem(image: UIImage(named: "previous")!, style: .plain, target: self, action: #selector(DetailsFormViewController.previousRecord(_:)))
        ]*/

        installSwipeGestureRecognizer()
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
    
    open override func viewWillAppear(_ animated: Bool) {
        if let table = self.view.table {
            checkActions(table)
        } else {
            assertionFailure("No table set when loading")
        }
    }
    
    @IBAction open func previousRecord(_ sender: Any!) {
         // TODO anination, like transitioning on self...
        // could use segue
         self.previousRecord()
    }

    @IBAction open func nextRecord(_ sender: Any!) {
        self.nextRecord()
    }
    
    @IBAction open func deleteRecord(_ sender: Any!) {
        self.deleteRecord()
    }
    
    func swipeLeft(_ sender: UISwipeGestureRecognizer!) {
        self.previousRecord(sender)
    }
    func swipeRight(_ sender: UISwipeGestureRecognizer!) {
        self.nextRecord(sender)
    }
    
}

open class DetailsFormTableViewController: UITableViewController, DetailsFormController {
    
    open var hasPreviousRecord: Bool = false
    open var hasNextRecord: Bool = false

    open override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    open override func viewWillAppear(_ animated: Bool) {
        if let table = self.view.table {
            checkActions(table)
        } else {
            assertionFailure("No table set when loading")
        }
    }

    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let staticCell = super.tableView(tableView, cellForRowAt: indexPath)
        staticCell.tableView = self.tableView

        staticCell.record = self.tableView.record
        staticCell.table = self.tableView.table

        return staticCell
    }


}

fileprivate extension UITableView {

    // use only for static table view and debug
    var cells: [UITableViewCell] {
        var cells = [UITableViewCell]()
        let sections = self.numberOfSections
        for section in 0..<sections {
            let rows = self.numberOfRows(inSection: section)
            for row in 0..<rows {
                if let cell = self.cellForRow(at: IndexPath(row: row, section: section)) {
                    cells.append(cell)
                }
            }
        }
        return cells
    }

}
