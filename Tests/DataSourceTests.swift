//
//  DataSourceTests.swift
//  QMobileUITests
//
//  Created by Eric Marchand on 14/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import XCTest
@testable import QMobileUI

import UIKit
// import CoreData
import Prephirences
import QMobileDataStore

class DataSourceTests: XCTestCase {

    let cellIdentifier = "Entity"
    let tableName = "Entity"
    let sectionFieldname = "string"
    let field = "string"
    var tableView: UITableView!
    
    let timeout: TimeInterval = 20
    
    let waitHandler: XCWaitCompletionHandler = { error in
        if let error = error {
            XCTFail("Failed to wait expectation: \(error)")
        }
    }

    var dataStore: DataStore {
        return QMobileDataStore.dataStore
    }
    
    override func setUp() {
        super.setUp()
        
        tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 100, height: 600))
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        
        let bundle = Bundle(for: DataSourceTests.self)
        
        Bundle.dataStore = bundle
        Bundle.dataStoreKey = "CoreDataModel"
        
        // XXX test in memory, or drop data
        
        let expectation = self.expectation(description: #function)
        dataStore.dropAndLoad { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }

        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testDataSourceInsert() {
        let fetchedResultsController = dataStore.fetchedResultsController(tableName: tableName, sectionNameKeyPath: sectionFieldname)
        let dataSource = DataSource(tableView: tableView, fetchedResultsController: fetchedResultsController)
        let expectation = self.expectation(description: "Inserted object not retrieve in data source")

        let randomString = UUID().uuidString
        dataSource.tableConfigurationBlock = { [unowned self] cell, record, index in
            if record[self.field] as? String == randomString {
                expectation.fulfill()
            }
        }

        tableView.dataSource = dataSource
        tableView.reloadData()

        let result = dataStore.perform(.background) { [unowned self] context, save in
            
            let record = context.create(in: self.tableName)
            record?[self.field] = randomString

            try! save()
        }
        XCTAssertTrue(result, "store not loaded to perform task")

        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }

}

extension DataStore {
    
    func dropAndLoad(completionHandler: QMobileDataStore.CompletionHandler?) {
        drop { _ in
            self.load(completionHandler: completionHandler)
        }
    }

}
