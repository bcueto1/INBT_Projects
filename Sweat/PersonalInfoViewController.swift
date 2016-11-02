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
    
    let patient = Patient()
    
    @IBOutlet weak var idTextField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        let idAlert = UIAlertController(title: "Alert", message: "Please re-enter your Patient ID properly",
                                        preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        if (idTextField.text! == "") {
            present(idAlert, animated: true, completion: nil)
            return false
        } else {
            return true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        updatePatientID();
        
    }
    
    func updatePatientID() {
        patient.ID = idTextField.text!
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
