//
//  RealTimeCalibrateViewController.swift
//  Sweat
//
//  Created by Brian Cueto on 11/1/16.
//  Copyright © 2016 Brian_INBT. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

extension String {
    
}

class RealTimeCalibrateViewController: UIViewController {
    
    /* -- Declare Variables and Outlets -- */
    let calibration = Calibration()
    var patient = Patient()
    var dataCounter : Int = 0
    var concStandardValue: Double = 0
    var concValue: Double = 0
    var voltValue: Double = 0
    var concStandardValueString: String = ""
    var concValueString: String = ""
    var voltValueString: String = ""
    @IBOutlet weak var enterConcValue: UILabel!
    @IBOutlet weak var enterConcValueTextField: UITextField!
    @IBOutlet weak var enterVoltLabel: UILabel!
    @IBOutlet weak var voltView: UIView!
    @IBOutlet weak var voltLabel: UILabel!
    @IBOutlet weak var startRun: UIButton!
    @IBOutlet weak var controlView: UIView!
    @IBOutlet weak var controlViewLabel: UILabel!
    @IBOutlet weak var enterRun: UIButton!
    @IBOutlet weak var calibrateButton: UIButton!
    @IBOutlet weak var refValueLabel: UILabel!
    @IBOutlet weak var refValueTextField: UITextField!
    @IBOutlet weak var enterRefValue: UIButton!
    
    
    //--- Main/Segue functions -- 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        enterConcValue.isHidden = true
        enterConcValueTextField.isHidden = true
        enterVoltLabel.isHidden = true
        voltView.isHidden = true
        voltLabel.isHidden = true
        startRun.isHidden = true
        controlView.isHidden = true
        controlViewLabel.isHidden = true
        enterRun.isHidden = true
        calibrateButton.isHidden = true
        refValueLabel.isHidden = false
        refValueTextField.isHidden = false
        enterRefValue.isHidden = false
        canEnterData()
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        let idAlert = UIAlertController(title: "Alert", message: "Not enough data entered!", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        idAlert.addAction(okAction)
        if (dataCounter < 3) {
            present(idAlert, animated: true, completion: nil)
            return false
        } else {
            return true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        updateCalibration()
        // Passes the instance of the Calibration class created by this view controller to the two tab bar view controlllers: CalibrationViewController and ExperimentViewController. The instance of the Calibration class has all the information entered by the user in the calibrate view controlled by this view controller.
        if (segue.identifier == "calibrateSegue") {
            // Get a reference to the destination view controller
            let tabBarViewController = segue.destination as! UITabBarController
            let firstViewController = tabBarViewController.viewControllers![0] as! CalibrationViewController
            let secondViewController = tabBarViewController.viewControllers![1] as! ExperimentViewController
            firstViewController.calibration = calibration
            secondViewController.calibration = calibration
            secondViewController.patient = patient
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /* ----- UI Functions ------ */
    @IBAction func enterRefValuePressed(_ sender: Any) {
        if Double(refValueTextField.text!) != nil {
            concStandardValue = Double(refValueTextField.text!)!
            concStandardValueString += String(concStandardValue)

            //Unhide rest of features/hide the reference stuff
            enterConcValue.isHidden = false
            enterConcValueTextField.isHidden = false
            enterVoltLabel.isHidden = false
            voltView.isHidden = false
            voltLabel.isHidden = false
            startRun.isHidden = false
            controlView.isHidden = false
            controlViewLabel.isHidden = false
            enterRun.isHidden = false
            calibrateButton.isHidden = false
            refValueLabel.isHidden = true
            refValueTextField.isHidden = true
            enterRefValue.isHidden = true
        } else {
            let alert = UIAlertController(title: "Alert", message: "Please enter valid reference", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            present(alert,animated: true, completion: nil)
        }
    }

    @IBAction func startisPressed(_ sender: Any) {
        if Double(enterConcValueTextField.text!) != nil {
            controlView.backgroundColor = UIColor.red
            controlViewLabel.text = "STOP"
            concValue = Double(enterConcValueTextField.text!)!
            voltValue = getVoltValue(cValue: concValue)
            controlView.backgroundColor = UIColor.green
            controlViewLabel.text = "READY"
        } else {
            let alert = UIAlertController(title: "Alert", message: "Please enter valid concentration", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
        }
        canEnterData()
    }

    @IBAction func enterIsPressed(_ sender: Any) {
        dataCounter += 1
        concValueString += String(concValue) + " "
        voltValueString += String(voltValue) + " "
    }

    /* ----- CUSTOM FUNCTIONS ------ */

    func canEnterData() {
        if (controlView.backgroundColor == UIColor.red) {
            enterRun.isEnabled = false
        }
        if (controlView.backgroundColor == UIColor.green) {
            enterRun.isEnabled = true
        }
    }
    
    func getVoltValue(cValue: Double) -> Double {
        return 0.0
    }

    func updateCalibration() {
        calibration.concStandardText = concStandardValueString
        calibration.concStandard = concStandardValue
        //Get rid of the extra space at the end
        calibration.concText = concValueString.substring(to: concValueString.endIndex)
        calibration.voltText = voltValueString.substring(to: voltValueString.endIndex)
    }
/*
    /* ----- BLUETOOTH FUNCTIONS ------ */
    // BLE properties
    var centralManager : CBCentralManager!
    var sensorPeripheral : CBPeripheral!
    
    // Services and characteristics of interest
    let adcUUID = "A6322521-EB79-4B9F-9152-19DAA4870418"
    let voltUUID = "F90EA017-F673-45B8-B00B-16A088A2ED62"
    
    func stopScan() {
        self.centralManager.stopScan()
        timer?.invalidate()
        timer = nil
    }
    
    // Check status of BLE hardware
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn && launchBool == true {
            // Scan for peripherals if BLE is turned on
            central.scanForPeripherals(withServices: nil, options: nil)
            //print("cool timer start")
            self.statusLabel.text = "Searching for BLE Devices"
            timer = Timer.scheduledTimer(timeInterval: 20, target: self, selector: #selector(stopScan), userInfo: nil, repeats: true)
            print("still running")
        }
        else {
            // Can have different conditions for all states if needed - print generic message for now
            print("Bluetooth switched off or not initialized")
        }
    }
    
    // Check out the discovered peripherals to find sensor
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        
        let deviceName = "BlueVolt"
        let nameOfDeviceFound = (advertisementData as NSDictionary).object(forKey: CBAdvertisementDataLocalNameKey) as? NSString
        /*
         if timer == 10 {
         self.centralManager.stopScan()
         timer!.invalidate()
         timer = nil
         print("cool timer stop")
         }
         */
        if (nameOfDeviceFound?.isEqual(to: deviceName))!{
            // Update Status Label
            self.statusLabel.text = "Sensor Found"
            
            // Stop scanning
            self.centralManager.stopScan()
            // Set as the peripheral to use and establish connection
            self.sensorPeripheral = peripheral
            self.sensorPeripheral.delegate = self
            self.centralManager.connect(peripheral, options: nil)
        }
        else {
            self.statusLabel.text = "Sensor NOT Found"
        }
    }
    
    
    // Discover services of the peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.statusLabel.text = "Discovering peripheral services"
        peripheral.discoverServices(nil)
    }
    
    
    // Check if the service discovered is a valid adc service
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        self.statusLabel.text = "Looking at peripheral services"
        for service in peripheral.services! {
            let thisService = service as CBService
            if String(describing: service.uuid) == adcUUID {
                // Discover characteristics of IR Temperature Service
                peripheral.discoverCharacteristics(nil, for: thisService)
                print("Works!")
            }
            else {
                print("Did not work")
            }
            // Uncomment to print list of UUIDs
            print(thisService.uuid)
        }
    }
    
    
    //Look for valid volt characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        self.statusLabel.text = "Looking at the service's characteristics"
        
        // 0x01 data byte to enable sensor
        //var enableValue = 2
        //let enablyBytes = NSData(bytes: &enableValue, length: sizeof(UInt16))
        
        // check the uuid of each characteristic to find config and data characteristics
        for characteristic in service.characteristics! {
            thisCharacteristic = characteristic as CBCharacteristic
            // check for data characteristic
            if String(describing: thisCharacteristic!.uuid) == voltUUID {
                // Enable Sensor Notification
                self.sensorPeripheral.setNotifyValue(true, for: thisCharacteristic!)
                print("Works!!!")
            }
            print(thisCharacteristic!.uuid)
        }
    }
*/
    
    
}
