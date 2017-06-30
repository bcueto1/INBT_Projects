//
//  LoadCalibrateViewController.swift
//  Sweat
//
//  Created by Brian Cueto on 11/1/16.
//  Copyright © 2016 Brian_INBT. All rights reserved.
//

import Foundation
import UIKit

class LoadCalibrateViewController: UIViewController {
    
    let calibration = Calibration()
    var patientID: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    //Function notifies the view controller that a segue is about to be performed.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        getCalibration()

        if (segue.identifier == "calibrateSegue") {
            // Get a reference to the destination view controller
            let tabBarViewController = segue.destination as! UITabBarController
            let firstViewController = tabBarViewController.viewControllers![0] as! CalibrationViewController
            let secondViewController = tabBarViewController.viewControllers![1] as! ExperimentViewController
            firstViewController.calibration = calibration
            secondViewController.calibration = calibration
            secondViewController.patientID = self.patientID
        }
    }
    
    func getCalibration() {
        
    }
    
    
}
