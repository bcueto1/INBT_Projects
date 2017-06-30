//
//  CalibrateMenuViewController.swift
//  Sweat
//
//  Created by Brian Cueto on 10/28/16.
//  Copyright © 2016 Brian_INBT. All rights reserved.
//

import Foundation
import UIKit

class CalibrateMenuViewController: UIViewController {
    
    var patientID: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "printValueSegue") {
            let DestViewController = segue.destination as! CalibrateViewController
            DestViewController.patientID = self.patientID
        }
        if (segue.identifier == "realTimeSegue") {
            let DestViewControllerTwo = segue.destination as! RealTimeCalibrateViewController
            DestViewControllerTwo.patientID = self.patientID
        }
        if (segue.identifier == "loadCalibrateSegue") {
            let DestViewControllerThree = segue.destination as! LoadCalibrateViewController
            DestViewControllerThree.patientID = self.patientID
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
