//
//  CollectionViewController.swift
//  DemoTabbedApplication
//
//  Created by Eric Marchand on 15/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit
import QMobileUI
import TRMosaicLayout

class EntityListFormCollection2: ListFormCollection {
    //private lazy var listLayout: DisplaySwitchLayout = DisplaySwitchLayout(staticCellHeight: 128, nextLayoutStaticCellHeight: 128, layoutState: .list)
   // private lazy var gridLayout: DisplaySwitchLayout = DisplaySwitchLayout(staticCellHeight: 128, nextLayoutStaticCellHeight: 128, layoutState: .grid)

    public override var tableName: String {
        return "Entity"
    }
    override func onLoad() {
        super.onLoad()

        let mosaicLayout = TRMosaicLayout()
        self.collectionView?.collectionViewLayout = mosaicLayout

        mosaicLayout.delegate = self
       // self.collectionView?.contentInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        ///self.collectionView?.backgroundView = UIImageView(image: UIImage(named: "profile-bg")!)

        //self.collectionView?.collectionViewLayout = CoverFlowLayout()

        //self.collectionView?.collectionViewLayout = CircleLayout()

       //self.collectionView?.collectionViewLayout = listLayout

       // self.collectionView?.emptyDataSetSource = self
       // self.collectionView?.emptyDataSetDelegate = self

    }

    /*func collectionView(collectionView: UICollectionView, transitionLayoutForOldLayout fromLayout: UICollectionViewLayout, newLayout toLayout: UICollectionViewLayout) -> UICollectionViewTransitionLayout {
        let customTransitionLayout = TransitionLayout(currentLayout: fromLayout, nextLayout: toLayout)
        return customTransitionLayout
    }*/

    // MARK: - Actions   
    fileprivate var isTransitionAvailable = true
   // fileprivate var layoutState: LayoutState = .list

    private let animationDuration: TimeInterval = 0.3

    @IBAction func buttonTapped(_ sender: AnyObject) {
        if !isTransitionAvailable {
            return
        }
        /*let transitionManager: TransitionManager
        if layoutState == .list {
            layoutState = .grid
            transitionManager = TransitionManager(duration: animationDuration, collectionView: collectionView!, destinationLayout: gridLayout, layoutState: layoutState)
        } else {
            layoutState = .list
            transitionManager = TransitionManager(duration: animationDuration, collectionView: collectionView!, destinationLayout: listLayout, layoutState: layoutState)
        }
        transitionManager.startInteractiveTransition()*/
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

extension EntityListFormCollection2: TRMosaicLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, mosaicCellSizeTypeAtIndexPath indexPath: IndexPath) -> TRMosaicCellType {
          return indexPath.item % 3 == 0 ? TRMosaicCellType.big : TRMosaicCellType.small
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: TRMosaicLayout, insetAtSection: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 3, left: 2, bottom: 3, right: 4)
    }

    func heightForSmallMosaicCell() -> CGFloat {
        return 150
    }

}
