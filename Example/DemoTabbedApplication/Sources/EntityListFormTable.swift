//
//  TableViewController.swift
//  DemoTabbedApplication
//
//  Created by Eric Marchand on 15/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit
import QMobileUI
import AZDialogView
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

        let dialog = AZDialogViewController(title: "Refresh data", message: "")
        dialog.allowDragGesture = true

        var cancellable: Cancellable? = nil

        let action = AZDialogAction(title: "Launch") { dialog in

            dialog.removeAction(at: 0)

            dialog.message = "Updating..."

            let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
            let container = dialog.container
            dialog.container.addSubview(indicator)
            indicator.translatesAutoresizingMaskIntoConstraints = false
            indicator.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
            indicator.centerYAnchor.constraint(equalTo: container.centerYAnchor).isActive = true
            indicator.startAnimating()

            cancellable = dataSync { result in
                DispatchQueue.main.async {
                    dialog.removeAllActions()

                    switch result {
                    case .success:
                        dialog.message = "Success"
                        print("success")
                    case .failure(let error):
                        // TODO error sync message
                        dialog.message = "Failed to synchonize data \(error)"

                        print("error \(error)")
                    }

                    self.refreshEnd()

                    let dismissAction = AZDialogAction(title: "Dismiss") { dialog in
                        dialog.dismiss()
                    }
                    dialog.addAction(dismissAction)

                    DispatchQueue.main.after(10) {
                        dialog.dismiss()
                    }
                }
            }

        }
        dialog.addAction(action)

       let cancelAction = AZDialogAction(title: "Cancel") { dialog in

            cancellable?.cancel()

            //add your actions here.
            dialog.dismiss()

            self.refreshEnd()
        }

        dialog.addAction(cancelAction)

        dialog.show(in: self)

        //let dataSync = ApplicationLoadDataStore.castedInstance.dataSync
        // _ = dataSync.sync { _ in
        // self.dataSource.performFetch()

        //}
    }

    func refreshEnd() {
        self.refreshControl?.endRefreshing()
        self.onRefreshEnd()
    }

    func loadingIndicator() {
        let dialog = AZDialogViewController(title: "Loading...", message: "Logging you in, please wait")

        let container = dialog.container
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        dialog.container.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
        indicator.centerYAnchor.constraint(equalTo: container.centerYAnchor).isActive = true
        indicator.startAnimating()

        /*dialog.buttonStyle = { (button, height, position) in
            button.setBackgroundImage(UIImage.imageWithColor(self.primaryColorDark), for: .highlighted)
            button.setTitleColor(UIColor.white, for: .highlighted)
            button.setTitleColor(self.primaryColor, for: .normal)
            button.layer.masksToBounds = true
            button.layer.borderColor = self.primaryColor.cgColor
        }*/

        //dialog.animationDuration = 5.0
        dialog.customViewSizeRatio = 0.2
        dialog.dismissDirection = .none
        dialog.allowDragGesture = false
        dialog.dismissWithOutsideTouch = true
        dialog.show(in: self)

        let when = DispatchTime.now() + 3  // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            dialog.message = "Preparing..."
        }

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 4) {
            dialog.message = "Syncing accounts..."
        }

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
            dialog.title = "Ready"
            dialog.message = "Let's get started"
            dialog.image = #imageLiteral(resourceName: "image")
            dialog.customViewSizeRatio = 0
            dialog.addAction(AZDialogAction(title: "Go", handler: { (dialog) -> Void in
                dialog.cancelEnabled = !dialog.cancelEnabled
            }))
            dialog.dismissDirection = .bottom
            dialog.allowDragGesture = true
        }

        /*dialog.cancelButtonStyle = { (button,height) in
            button.tintColor = self.primaryColor
            button.setTitle("CANCEL", for: [])
            return false
        }*/

    }

}
