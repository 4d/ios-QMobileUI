//
//  DataSource+UIPageViewControllerDataSource.swift
//  QMobileUI
//
//  Created by Eric Marchand on 24/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit
import QMobileDataStore
/*
extension DataSource: UIPageViewControllerDataSource {

   public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let viewController = viewController as? IndexableViewController, let pageIndex = viewController.pageIndex, pageIndex > 0 {
            return viewControllerAtIndex(pageIndex - 1)
        }

        return nil
    }

   public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let viewController = viewController as? IndexableViewController, let pageIndex = viewController.pageIndex, pageIndex < self.fetchedResultsController.count - 1 {
            return viewControllerAtIndex(pageIndex + 1)
        }
        return nil
    }

   public func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return self.fetchedResultsController.count
    }

    public func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }

}

protocol ViewControllerProvider {
    var initialViewController: UIViewController { get }
    func viewControllerAtIndex(_ index: IndexPath) -> UIViewController?
}

protocol IndexableViewController {
    var pageIndex: IndexPath?
}
*/
