//
//  TableViewController.swift
//  DemoTabbedApplication
//
//  Created by Eric Marchand on 15/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit
import QMobileUI
import Moya

/// Generated controller for Entity table.
/// Do not edit name or override tableName
class EntityListFormTable: ListFormTable {

    public override var tableName: String {
        return "Entity"
    }

    override func onLoad() {
        //self.tableView.backgroundView = UIImageView(image: UIImage(named: "profile-bg")!)

        //self.tableView.emptyDataSetSource = self
        //self.tableView.emptyDataSetDelegate = self

       // self.tableView.sect
    }

    @IBAction override open func refresh(_ sender: Any?) {
        onRefreshBegin()

                    self.refreshEnd()

    }

    func refreshEnd() {
        self.refreshControl?.endRefreshing()
        self.onRefreshEnd()
    }

}
