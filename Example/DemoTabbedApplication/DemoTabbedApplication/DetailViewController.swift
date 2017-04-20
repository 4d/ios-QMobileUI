//
//  DetailViewController\.swift
//  DemoTabbedApplication
//
//  Created by Eric Marchand on 16/03/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit
import QMobileUI

class EntityDetailsFormTableViewController: DetailsFormTable {
    
    override func onWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        self.navigationController?.setToolbarHidden(false, animated: animated)
    }

}


class EntityDetailsFormViewController: DetailsFormBare {
    
    override func onWillAppear(_ animated: Bool) {
         
    }

    @IBAction open override func previousRecord(_ sender: Any!) {
         /*if let center = viewCenter(sender) {
            self.view.animateCircular(withDuration: 0.5, center: center, revert: true, animations: {
                super.previousRecord(sender)
                self.view.backgroundColor =   self.view.backgroundColor == .red ? .blue : .red
            })
         } else {*/
            super.previousRecord(sender)
       /* }*/
    }
    
    @IBAction open override func nextRecord(_ sender: Any!) {
        /*if let center = viewCenter(sender) {
            self.view.animateCircular(withDuration: 0.5, center: center, revert: false, animations: {
                super.nextRecord(sender)
                self.view.backgroundColor =   self.view.backgroundColor == .red ? .blue : .red
            })
        } else {*/
            super.nextRecord(sender)
      /*  }*/
    }
    
    
    func viewCenter(_ sender: Any) -> CGPoint? {
        if let view = sender as? UIView {
            return  view.center
        }
        else if let item = sender as? UIBarItem, let view = item.value(forKey: "view") as? UIView {
            return  view.center
        }
        return nil
    }
}
