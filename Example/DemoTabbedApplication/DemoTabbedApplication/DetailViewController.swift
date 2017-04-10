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

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        self.navigationController?.setToolbarHidden(false, animated: animated)
    }

}
