//
//  CalibrateViewController.swift
//  Sweat
//
//  Created by Brian Cueto on 10/25/16.
//  Copyright © 2016 Brian_INBT. All rights reserved.
//

import Foundation
import UIKit

class CalibrateViewController: UIViewController, UITextFieldDelegate {
    
    // Enter safety condition for this text field (concStandardTextField) later -- dangerous right now. *****
    @IBOutlet weak var concStandardTextField: UITextField!
    @IBOutlet weak var concTextField: UITextField!
    @IBOutlet weak var voltTextField: UITextField!
    
    let calibration = Calibration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        concStandardTextField.delegate = self
        concTextField.delegate = self
        voltTextField.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    // SEGUE FUNCTIONS
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        let concTuple = calibration.valuesChecker(textField: concTextField.text)
        let voltTuple = calibration.valuesChecker(textField: voltTextField.text)
        let equalLength = concTuple.valuesOptional.count == voltTuple.valuesOptional.count
        
        // ALERT CODE
        let calibrationAlert = UIAlertController(title: "Alert", message: "Please re-enter concentration and voltage values properly", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        //let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        calibrationAlert.addAction(okAction)
        //calibrationAlert.addAction(cancelAction)
        
        switch true {
        case !equalLength where !equalLength == !concTuple.check && !equalLength == !voltTuple.check:
            calibrationAlert.message = "Please address the following:\n"+"Number of concentration and voltage values not equal\n"+"All concentration values not numeric\n"+"All voltage values not numeric"
            present(calibrationAlert, animated: true, completion: nil)
            return false
        case !equalLength where !equalLength == !concTuple.check:
            calibrationAlert.message = "Please address the following:\n"+"Number of concentration and voltage values not equal\n"+"All concentration values not numeric"
            present(calibrationAlert, animated: true, completion: nil)
            return false
        case !equalLength where !equalLength == !voltTuple.check:
            calibrationAlert.message = "Please address the following:\n"+"Number of concentration and voltage values not equal\n"+"All voltage values not numeric"
            present(calibrationAlert, animated: true, completion: nil)
            return false
        case !equalLength:
            calibrationAlert.message = "Please address the following:\n"+"Number of concentration and voltage values not equal"
            present(calibrationAlert, animated: true, completion: nil)
            return false
        case !concTuple.check where !concTuple.check == !voltTuple.check:
            calibrationAlert.message = "Please address the following:\n"+"All concentration values not numeric\n"+"All voltage values not numeric"
            present(calibrationAlert, animated: true, completion: nil)
            return false
        case !concTuple.check:
            calibrationAlert.message = "Please address the following:\n"+"All concentration values not numeric"
            present(calibrationAlert, animated: true, completion: nil)
            return false
        case !voltTuple.check:
            calibrationAlert.message = "Please address the following:\n"+"All voltage values not numeric"
            present(calibrationAlert, animated: true, completion: nil)
            return false
        default:
            print("Concentration and voltage values are appropriate entries")
            return true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        updateCalibration()
        if (segue.identifier == "calibrateSegue") {
            // Get a reference to the destination view controller
            let tabBarViewController = segue.destination as! UITabBarController
            let firstViewController = tabBarViewController.viewControllers![0] as! CalibrationViewController
            let secondViewController = tabBarViewController.viewControllers![1] as! ExperimentViewController
            firstViewController.calibration = calibration
            secondViewController.calibration = calibration
        }
    }
    
    // TOUCH FUNCTIONS
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // CUSTOM FUNCTIONS
    
    func updateCalibration() -> Calibration {
        calibration.concStandardText = concStandardTextField.text!
        calibration.concText = concTextField.text!
        calibration.voltText = voltTextField.text!
        calibration.concStandard = Double(calibration.concStandardText)!
        return calibration
    }
    
}
