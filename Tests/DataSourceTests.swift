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
    
    let timeout: TimeInterval = 10
    
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
        
        
        let bundle = Bundle(for: DataSourceTests.self)
        
        Bundle.dataStore = bundle
        Bundle.dataStoreKey = "CoreDataModel"
        
        
        if !dataStore.isLoaded {
            var loaded = false
            
            dataStore.load { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    XCTFail("\(error)")
                }
                loaded = true
            }
            
            let timeOut = Date(timeIntervalSinceNow: 10)
            while (!loaded && Date() < timeOut) {
                RunLoop.current.run(mode: RunLoopMode.defaultRunLoopMode, before: Date(timeIntervalSinceNow: 1))
            }
        }
    }

    override func tearDown() {
        super.tearDown()
        
        /*var dropped = false
        dataStore.drop { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("\(error)")
            }
            dropped = true
        }
        let timeOut = Date(timeIntervalSinceNow: 10)
        while (!dropped && Date() < timeOut) {
            RunLoop.current.run(mode: RunLoopMode.defaultRunLoopMode, before: Date(timeIntervalSinceNow: 1))
        }*/
    }

    func testInsertInTableView() {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 100, height: 600))
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        
        let fetchedResultsController = dataStore.fetchedResultsController(tableName: tableName, sectionNameKeyPath: nil)
        let dataSource = DataSource(tableView: tableView, fetchedResultsController: fetchedResultsController)
        let expectation = self.expectation(description: "Inserted object not retrieve in table view in data source")

        let randomString = UUID().uuidString
        dataSource.tableConfigurationBlock = { [unowned self] cell, record, index in
            if record[self.field] as? String == randomString {
                expectation.fulfill()
            }
        }

        tableView.dataSource = dataSource
        tableView.reloadData()

        let result = dataStore.perform(.background) { [unowned self] context in
            
            let record = context.create(in: self.tableName)
            record?[self.field] = randomString

            try! context.commit()
        }
        XCTAssertTrue(result, "store not loaded to perform task")

        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }
    
    func testInsertInCollectionView() {

        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 20, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: 200, height: 100)
        let collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: 500, height: 1200), collectionViewLayout: layout)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
        
        let fetchedResultsController = dataStore.fetchedResultsController(tableName: tableName, sectionNameKeyPath: sectionFieldname)
        let dataSource = DataSource(collectionView: collectionView, fetchedResultsController: fetchedResultsController)
        let expectation = self.expectation(description: "Inserted object not retrieve in collection view in data source")
        
        let randomString = UUID().uuidString
        dataSource.collectionConfigurationBlock = { [unowned self] cell, record, index in
            if record[self.field] as? String == randomString {
                expectation.fulfill()
            }
        }

        collectionView.dataSource = dataSource
        collectionView.reloadData()
        
        let result = dataStore.perform(.background) { [unowned self] context in
            
            let record = context.create(in: self.tableName)
            record?[self.field] = randomString

            try! context.commit()
        }
        XCTAssertTrue(result, "store not loaded to perform task")
        
        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }
    
    
    func _testDeleteInTableView() {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 100, height: 600))
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        
        let fetchedResultsController = dataStore.fetchedResultsController(tableName: tableName, sectionNameKeyPath: nil)
        let dataSource = DataSource(tableView: tableView, fetchedResultsController: fetchedResultsController)
        let expectation = self.expectation(description: "Deleted object not retrieve in table view in data source")
        
        let randomString = UUID().uuidString
        dataSource.tableConfigurationBlock = { [unowned self] cell, record, index in
            if record[self.field] as? String == randomString {
                expectation.fulfill()
            }
        }
        
        // TODO find a way to detect cell has been removed
        
        tableView.dataSource = dataSource
        tableView.reloadData()
        
        let result = dataStore.perform(.background) { [unowned self] context in
            let predicate = NSPredicate.true
            do {
                let done = try context.delete(in: self.tableName, matching: predicate)
                XCTAssertTrue(done>0)
            } catch {
                XCTFail(" Failed to delete \(error)")
            }

            try! context.commit()
        }
        XCTAssertTrue(result, "store not loaded to perform task")
        
        self.waitForExpectations(timeout: timeout, handler: waitHandler)
    }

}

extension DataStore {
    
    func dropAndLoad(completionHandler: QMobileDataStore.DataStore.CompletionHandler?) {
        drop { _ in
            self.load(completionHandler: completionHandler)
        }
    }

}
