//
//  EntityListFormCollection+EmptyDataSet.swift
//  DemoTabbedApplication
//
//  Created by Eric Marchand on 03/05/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation

import DZNEmptyDataSet
extension EntityListFormCollection/*: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate*/ {
    
    public func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "no result, here could load remote data...")
    }
    
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView!) -> UIColor! {
        return .white
    }
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
}

extension EntityListFormTable/*: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate*/ {
    
    // DZNEmptyDataSetSource
    public func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "no result, here could load remote data...")
    }
    
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView!) -> UIColor! {
        return .white
    }
    
    // DZNEmptyDataSetDelegate
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
}

class weqwe: UIViewController, DZNEmptyDataSetSource {
    
}
