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

    // NOTE: The terms variable & property and method & function are used synonymously throughout the comments in ALL files. Not good practice, but should not be confusing with this disclaimer.
    
    // ---------- CLASSES, PROPERTIES AND BUILT-IN FUNCTIONS ----------
    
    // Textfield variable for concentration of standard solution in sensor -- need safety condition for erroneous input by user for this textfield, which can be added to the non-elegant switch cases below.
    @IBOutlet weak var concStandardTextField: UITextField!
    @IBOutlet weak var concTextField: UITextField!
    @IBOutlet weak var voltTextField: UITextField!
    
    let calibration = Calibration()
    var patientID: String!
    
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
    
    // -------- SEGUE FUNCTIONS --------
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
        
        // Non-elegant switch cases below make sure that the inputs to the textfields made by the user are valid, if they are not valid inputs then a warning pops up telling the user why entries are not valid. Switch cases are based on the booleans .check and equalLength.
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
    
    //Function notifies the view controller that a segue is about to be performed.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        updateCalibration()
        
        if (segue.identifier == "calibrateSegue") {
            let tabBarViewController = segue.destination as! UITabBarController
            let firstViewController = tabBarViewController.viewControllers![0] as! CalibrationViewController
            let secondViewController = tabBarViewController.viewControllers![1] as! ExperimentViewController
            firstViewController.calibration = calibration
            secondViewController.calibration = calibration
            secondViewController.patientID = self.patientID
        }
    }
    
    // ------- TOUCH FUNCTIONS --------
    
    // Gets rid of keyboard when view is tapped outside of keyboard
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // Function gets rid of keyboard when return key is pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // CUSTOM FUNCTIONS
    
    func updateCalibration() {
        calibration.concStandardText = concStandardTextField.text!
        calibration.concText = concTextField.text!
        calibration.voltText = voltTextField.text!
        //Converts concStandardText string to double and passes to calibration.concStandard
        calibration.concStandard = Double(calibration.concStandardText)!
    }
    
}
