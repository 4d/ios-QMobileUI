//
//  DetailsFormViewController.swift
//  QMobileUI
//
//  Created by Eric Marchand on 22/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

open class DetailsFormViewController: UIViewController, DetailsFormController {

    open override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Configure table bar, COULD DO : do it automatically if to buttons already in bar
        //self.navigationItem.leftBarButtonItem = self.editButtonItem
        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(named: "previous")!, style: .plain, target: self, action: #selector(DetailsFormViewController.previousRecord(_:))),
            UIBarButtonItem(image: UIImage(named: "next")!, style: .plain, target: self, action: #selector(DetailsFormViewController.nextRecord(_:)))
        ]
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(DetailsFormViewController.swipeLeft(_:)))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
       
        let swipRight = UISwipeGestureRecognizer(target: self, action: #selector(DetailsFormViewController.swipeRight(_:)))
        swipRight.direction = .right
        self.view.addGestureRecognizer(swipRight)
        
        //swipeLeft.delegate = self
        //swipRight.delegate = self

    }
    
    @IBAction open func previousRecord(_ sender: Any!) {
         // TODO anination, like transitioning on self...
        // could use segue
         self.previousRecord()
    }
    @IBAction open func nextRecord(_ sender: Any!) {
        self.nextRecord()
    }
    
    func swipeLeft(_ sender: UISwipeGestureRecognizer!) {
        self.previousRecord(sender)
    }
    func swipeRight(_ sender: UISwipeGestureRecognizer!) {
        self.nextRecord(sender)
    }
    
}

open class DetailsFormTableViewController: UITableViewController, DetailsFormController {

    open override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let staticCell = super.tableView(tableView, cellForRowAt: indexPath)
        staticCell.tableView = self.tableView

        staticCell.record = self.tableView.record
        staticCell.table = self.tableView.table

        return staticCell
    }
    
    
    

}

extension UITableView {

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
