//
//  CollectionViewController.swift
//  DemoTabbedApplication
//
//  Created by Eric Marchand on 15/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit
import QMobileUI
import DisplaySwitcher

class EntityCollectionViewController: ListFormCollection {
    private lazy var listLayout: DisplaySwitchLayout = DisplaySwitchLayout(staticCellHeight: 128, nextLayoutStaticCellHeight: 128, layoutState: .list)
    private lazy var gridLayout: DisplaySwitchLayout = DisplaySwitchLayout(staticCellHeight: 128, nextLayoutStaticCellHeight: 128, layoutState: .grid)
    
    override func onLoad() {
        super.onLoad()
        
        self.collectionView?.contentInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        ///self.collectionView?.backgroundView = UIImageView(image: UIImage(named: "profile-bg")!)
    
    
        //self.collectionView?.collectionViewLayout = CoverFlowLayout()
        
        //self.collectionView?.collectionViewLayout = CircleLayout()
        
       //self.collectionView?.collectionViewLayout = listLayout
        
        self.collectionView?.emptyDataSetSource = self
        self.collectionView?.emptyDataSetDelegate = self
        
        print(self.refreshControl ?? "")
    }

    func collectionView(collectionView: UICollectionView, transitionLayoutForOldLayout fromLayout: UICollectionViewLayout, newLayout toLayout: UICollectionViewLayout) -> UICollectionViewTransitionLayout {
        let customTransitionLayout = TransitionLayout(currentLayout: fromLayout, nextLayout: toLayout)
        return customTransitionLayout
    }
    
    // MARK: - Actions   
    fileprivate var isTransitionAvailable = true
    fileprivate var layoutState: LayoutState = .list
    
    private let animationDuration: TimeInterval = 0.3
    
    @IBAction func buttonTapped(_ sender: AnyObject) {
        if !isTransitionAvailable {
            return
        }
        let transitionManager: TransitionManager
        if layoutState == .list {
            layoutState = .grid
            transitionManager = TransitionManager(duration: animationDuration, collectionView: collectionView!, destinationLayout: gridLayout, layoutState: layoutState)
        } else {
            layoutState = .list
            transitionManager = TransitionManager(duration: animationDuration, collectionView: collectionView!, destinationLayout: listLayout, layoutState: layoutState)
        }
        transitionManager.startInteractiveTransition()
        //rotationButton.isSelected = layoutState == .list
        //rotationButton.animationDuration = animationDuration
    }
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isTransitionAvailable = false
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        isTransitionAvailable = true
    }
    
}

import DZNEmptyDataSet
extension EntityCollectionViewController {
    
    public func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString!{
        return NSAttributedString(string: "no result, here could load remote data...")
    }
    
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView!) -> UIColor! {
        return .white
    }
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
}
