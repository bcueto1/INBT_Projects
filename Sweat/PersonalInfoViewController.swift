//
//  PersonalInfoViewController.swift
//  
//
//  Created by Brian Cueto on 10/24/16.
//
//

import Foundation

import UIKit

class PersonalInfoViewController: UIViewController {
    
    var patientID: String!
    @IBOutlet weak var idTextField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        let idAlert = UIAlertController(title: "Alert", message: "Please re-enter your Patient ID properly", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        idAlert.addAction(okAction)
        if (idTextField.text! == "") {
            present(idAlert, animated: true, completion: nil)
            return false
        } else {
            return true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.updatePatientID();
        let DestViewController = segue.destination as! CalibrateMenuViewController
        DestViewController.patientID = self.patientID
    }
    
    /* -- Custom functions -- */
    
    func updatePatientID() {
        self.patientID = self.idTextField.text!
    }
    

}
