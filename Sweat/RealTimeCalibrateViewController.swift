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

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
}

class RealTimeCalibrateViewController: UIViewController,
    CBCentralManagerDelegate, CBPeripheralDelegate {
    
    /* -- Declare Variables and Outlets -- */
    let calibration = Calibration()
    var patient = Patient()
    var dataCounter : Int = 0
    var concStandardValue: Double = 0
    var concValue: Double = 0
    var voltValue: Double = 0
    var voltArray = [Double]()
    var concStandardValueString: String = ""
    var concValueString: String = ""
    var voltValueString: String = ""
    var timer: Timer?
    var voltTimer: Timer?
    var bluetoothBool = false
    var thisCharacteristic: CBCharacteristic?
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
    @IBOutlet weak var statusLabel: UILabel!

    var launchBool: Bool = false {
        didSet {
            if launchBool == true {
                startRun.setTitle("Running", for: .normal)
                centralManager = CBCentralManager(delegate: self, queue: nil)
            } else {
                if self.sensorPeripheral != nil {
                    stopScan()
                    startRun.setTitle("Start", for: .normal)
                    self.sensorPeripheral?.setNotifyValue(false, for: thisCharacteristic!)
                    self.centralManager.cancelPeripheralConnection(sensorPeripheral!)
                    getVoltValue()
                    voltLabel.text = String(voltValue)
                    controlView.backgroundColor = UIColor.green
                    controlViewLabel.text = "READY"
                } else if timer != nil {
                    stopScan()
                    startRun.setTitle("Start", for: .normal)
                    self.statusLabel.text = "Disconnected"
                } else {
                    stopScan()
                    startRun.setTitle("Start", for: .normal)
                    self.statusLabel.text = "Peripheral not advertising properly, try again"
                }
            }
        }
    }
    
    func falseLaunch() {
        launchBool = false;
    }

    //--- Main/Segue functions -----//
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        setHiddens()
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
    }
    
    /* ----- UI Functions ------ */
    @IBAction func enterRefValuePressed(_ sender: Any) {
        if Double(refValueTextField.text!) != nil {
            concStandardValue = Double(refValueTextField.text!)!
            concStandardValueString += String(concStandardValue)
            setNotHiddens()
        } else {
            let alert = UIAlertController(title: "Alert", message: "Please enter valid reference", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            present(alert,animated: true, completion: nil)
        }
    }

    @IBAction func startisPressed(_ sender: Any) {
        if Double(enterConcValueTextField.text!) != nil {
            voltArray.removeAll()
            controlView.backgroundColor = UIColor.red
            controlViewLabel.text = "WAIT"
            concValue = Double(enterConcValueTextField.text!)!
            launchBool = true
            voltTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(falseLaunch), userInfo: nil, repeats: true)
        } else {
            let alert = UIAlertController(title: "Alert", message: "Please enter valid concentration", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
        }
    }

    @IBAction func enterIsPressed(_ sender: Any) {
        if (controlView.backgroundColor == UIColor.green) {
            dataCounter += 1
            concValueString += String(concValue) + " "
            voltValueString += voltLabel.text! + " "
            voltLabel.text = "";
            enterConcValue.text = "";
            concValue = 0;
            voltValue = 0;
            voltArray.removeAll()
            controlView.backgroundColor = UIColor.red
            controlViewLabel.text = ""
        } else {
            let enterAlert = UIAlertController(title: "Alert", message: "Data not allowed to be entered yet.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            enterAlert.addAction(okAction)
            present(enterAlert, animated: true, completion: nil)
        }
    }

    /* ----- CUSTOM FUNCTIONS ------ */

    func getVoltValue() {
        voltValue = voltArray[0]
        for volt in voltArray {
            if ((volt - voltValue) > 1.0 || (volt - voltValue) < -1.0) {
                voltValue = volt
            }
        }
    }

    func updateCalibration() {
        calibration.concStandardText = concStandardValueString
        calibration.concStandard = concStandardValue
        calibration.concText = concValueString.substring(to: concValueString.endIndex)
        calibration.voltText = voltValueString.substring(to: voltValueString.endIndex)
    }
    
    func setHiddens() {
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
    }
    
    func setNotHiddens() {
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
    }

    /* ----- BLUETOOTH FUNCTIONS ------ */
    // BLE properties
    var centralManager : CBCentralManager!
    var sensorPeripheral : CBPeripheral?
    
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
            self.statusLabel.text = "Searching for BLE Devices"
            //timer = Timer.scheduledTimer(timeInterval: 20.0, target: self, selector: #selector(stopScan), userInfo: nil, repeats: true)
            print("still running")
        }
        else {
            print("Bluetooth switched off or not initialized")
        }
    }
    
    // Check out the discovered peripherals to find sensor
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let deviceName = "BlueVolt"
        let nameOfDeviceFound = peripheral.name

        if (nameOfDeviceFound == deviceName){
            self.statusLabel.text = "Sensor Found"
            let tempPeripheral: CBPeripheral = peripheral
            self.sensorPeripheral = tempPeripheral
            self.sensorPeripheral?.delegate = self
            self.centralManager.connect(peripheral, options: nil)
            self.centralManager.stopScan()
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
                peripheral.discoverCharacteristics(nil, for: thisService)
                print("Works!")
            }
            else {
                print("Did not work")
            }
            print(thisService.uuid)
        }
    }
    
    
    //Look for valid volt characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        self.statusLabel.text = "Looking at the service's characteristics"

        // check the uuid of each characteristic to find config and data characteristics
        for characteristic in service.characteristics! {
            thisCharacteristic = characteristic as CBCharacteristic
            // check for data characteristic
            if String(describing: thisCharacteristic!.uuid) == voltUUID {
                // Enable Sensor Notification
                self.sensorPeripheral?.setNotifyValue(true, for: thisCharacteristic!)
                print("Works!!!")
            }
            print(thisCharacteristic!.uuid)
        }
    }
    
    // Get data values when they are updated
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        statusLabel.text = "Connected"
        
        if String(describing: characteristic.uuid) == voltUUID {

            // Convert NSData to array of signed 16 bit values
            let dataBytes = characteristic.value!
            let dataLength = dataBytes.count
            var dataArray = [UInt8](repeating: 0, count: dataLength)
            dataBytes.copyBytes(to: &dataArray, count: dataLength * MemoryLayout<Int16>.size)
            
            // Element 1 of the array will be ambient temperature raw value
            let voltsMeasurement = Double(dataArray[0])
            voltArray.append(voltsMeasurement)

        }
    }
    
    // If disconnected, show disconnected
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.statusLabel.text = "Disconnected"
    }

}
