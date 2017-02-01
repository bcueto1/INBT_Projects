//
//  ExperimentViewController.swift
//  Sweat
//
//  Created by Brian Cueto on 10/25/16.
//  Copyright © 2016 Brian_INBT. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth
import MessageUI
import Charts

class ExperimentViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, MFMailComposeViewControllerDelegate, ChartViewDelegate {
    
    // You may need to finagle with the general settings to get my code to work on your computer. Change deployment target to 9.3 if your phone is up-to-date. Try with and without changing deployment target if for some odd reason without changing is the one that works *********************
    // If you get a PID Message, just press stop and play again *********************
    @IBOutlet weak var concentrationLabel: UILabel!
    // Added a view objects to calibration and experiment views  that you can use (haven't linked up to their view controller code), ignore the auto-layout issues for now. *********************
    
    
    @IBOutlet weak var experimentChartView: LineChartView!
    @IBOutlet weak var connectButtonOutlet: UIButton!
    @IBAction func connectButtonAction(sender: UIButton) {
        launchBool = !launchBool
        experiment.launchBool = launchBool //true to false, false to true...
        //check = true
    }
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var mVLabel: UILabel!
    @IBOutlet weak var mMLabel: UILabel!
    
    //Lists the proper concentration and time when appropriate
    @IBOutlet weak var goodConcentration: UILabel!
    @IBOutlet weak var goodTime: UILabel!
    
    // Integrated email feature
    // Initialization of instances of classes and properties
    // Classes
    var calibration: Calibration?
    var experiment = Experiment()
    var patient = Patient()
    // Properties
    var experimentNumber: Int?
    var bluetoothBool = false
    var timer: Timer?
    var thisCharacteristic: CBCharacteristic?
    var initialMinutes: Double = 0
    var maxSize: Int = 0
    var timeDict = [String:[Double]]()
    var voltDict = [String:[Double]]()
    var concDict = [String:[Double]]()
    var timeDictString = [String:[String]]()
    var voltDictString = [String:[String]]()
    var concDictString = [String:[String]]()
    var timeArray = [Double]() // x values that need to to be plotted, updated within the second function peripheral *********************
    var minutesArray = [String]()
    var voltArray = [Double]() // doesn't need to be plotted *********************
    var concArray = [Double]() // y values that need to be plotted, updated similarly *********************
    var timeArrayString = [String]()
    var voltArrayString = [String]()
    var concArrayString = [String]()
    var timeMaxArrayString = [String]()
    var voltMaxArrayString = [String]()
    var concMaxArrayString = [String]()
    var tupleMaxArrayString = [String]()
    var voltsMeasurement: Double = 3
    var voltsMeasurementTest: Double = 3
    var concMeasurement: Double = 3

    //var check = false
    var launchBool: Bool = false {
        didSet {
            if launchBool == true {
                connectButtonOutlet.setTitle("Stop Experiment \(experimentNumber!)", for: .normal)
                // Initialize central manager on load
                centralManager = CBCentralManager(delegate: self, queue: nil)
                experimentNumber! += 1
                //let experiment = Experiment()
                //timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "fireStopWatch", userInfo: nil, repeats: true)
            } else {
                if self.sensorPeripheral != nil {
                    timeDict["Experiment \(experimentNumber!-1)"] = timeArray
                    voltDict["Experiment \(experimentNumber!-1)"] = voltArray
                    concDict["Experiment \(experimentNumber!-1)"] = concArray
                    if timeArray.count > maxSize {
                        maxSize = timeArray.count
                    }
                    initialMinutes = 0
                    minutesArray.removeAll()
                    timeArray.removeAll()
                    voltArray.removeAll()
                    concArray.removeAll()
                    experiment.emailBool = false
                    print(voltDict)
                    connectButtonOutlet.setTitle("Start Experiment \(experimentNumber!)", for: .normal)
                    self.sensorPeripheral?.setNotifyValue(false, for: thisCharacteristic!)
                    self.centralManager.cancelPeripheralConnection(sensorPeripheral!)
                    
                } else if timer != nil {
                    print("coooooool")
                    initialMinutes = 0
                    minutesArray.removeAll()
                    timeArray.removeAll()
                    voltArray.removeAll()
                    concArray.removeAll()
                    experimentNumber! -= 1
                    stopScan()
                    connectButtonOutlet.setTitle("Start Experiment \(experimentNumber!)", for: .normal)
                    self.statusLabel.text = "Disconnected"
                } else {
                    initialMinutes = 0
                    minutesArray.removeAll()
                    timeArray.removeAll()
                    voltArray.removeAll()
                    concArray.removeAll()
                    experimentNumber! -= 1
                    stopScan()
                    connectButtonOutlet.setTitle("Start Experiment \(experimentNumber!)", for: .normal)
                    self.statusLabel.text = "Peripheral not advertising properly, try again"
                }
                //timer?.invalidate()
                //timer = nil
                //myInt = 0
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        goodConcentration.isHidden = true;
        goodTime.isHidden = true;
        concentrationLabel.transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI_2)) //rotate the label?
        experimentNumber = 1
        configureChart()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // -------- Custom Functions ----------
    
    func convertVoltToConc(volt: Double, slope: Double, yint: Double, concStandard: Double) -> Double {
        let exponent = (volt - yint) / slope
        let conc = concStandard * pow(10.0,exponent)
        return conc
    }
    
    
    // ----------- Segue Functions ----------
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        // ALERT CODE
        let calibrationAlert1 = UIAlertController(title: "Alert", message: "Please stop current experiment to start new session or view last session", preferredStyle: .alert)
        let calibrationAlert2 = UIAlertController(title: "Alert", message: "You have data that hasn't been emailed. All data will be lost. Do you wish to proceed?", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        let yesAction = UIAlertAction(title: "Yes", style: .default, handler: {[weak self](action) -> Void in self?.performSegue(withIdentifier: "homeSegue", sender: self)})
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        calibrationAlert1.addAction(okAction)
        calibrationAlert2.addAction(yesAction)
        calibrationAlert2.addAction(cancelAction)
        
        //calibrationAlert.addAction(cancelAction)
        if  launchBool == true {
            present(calibrationAlert1, animated: true, completion: nil)
            return false
        } else if experiment.emailBool == false {
            present(calibrationAlert2, animated: true, completion: nil)
            return false
        } else {
            return true
        }
    }

    // ------- BLUETOOTH --------
    
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
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let deviceName = "BlueVolt"
        let nameOfDeviceFound = peripheral.name

        
        if (nameOfDeviceFound == deviceName) {
            // Update Status Label
            self.statusLabel.text = "Sensor Found"
            // Set as the peripheral to use and establish connection
            let tempPeripheral: CBPeripheral = peripheral
            self.sensorPeripheral = tempPeripheral
            self.sensorPeripheral?.delegate = self
            self.centralManager.connect(tempPeripheral, options: nil)
            // Stop scanning
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
                self.sensorPeripheral?.setNotifyValue(true, for: thisCharacteristic!)
                print("Works!!!")
            }
            print(thisCharacteristic!.uuid)
        }
    }
    
    // This function below gets called every time the app gets notified with a new value (function above) *********************
    // Get data values when they are updated
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        statusLabel.text = "Connected"
        
        if String(describing: characteristic.uuid) == voltUUID { // Real time plotting can probably occur within this if closure, this is where i append the received data to the arrays initialized at the beginning -- you can probably append these values to the plot views *********************
            
            let date = NSDate()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm:ss:SSS"
            let timeStamp = dateFormatter.string(from: date as Date)
            let timeStampStringArray = timeStamp.components(separatedBy: ":")
            let timeStampDoubleOptionalArray = timeStampStringArray.map({NumberFormatter().number(from: $0)?.doubleValue})
            let timeStampDoubleArray = timeStampDoubleOptionalArray.flatMap{$0}
            // Convert to minutes
            let seconds = timeStampDoubleArray[2] + timeStampDoubleArray[3]/1000
            let minutes = timeStampDoubleArray[0]*60 + timeStampDoubleArray[1] + seconds/60
            print(timeStamp)
            print(minutes)
            
            // Convert NSData to array of signed 16 bit values
            let dataBytes = characteristic.value!
            let dataLength = dataBytes.count
            var dataArray = [UInt8](repeating: 0, count: dataLength)
            dataBytes.copyBytes(to: &dataArray, count: dataLength * MemoryLayout<Int16>.size)
            
            // Element 1 of the array will be ambient temperature raw value
            voltsMeasurement = Double(dataArray[0])
            voltsMeasurementTest = voltsMeasurement / (5.78) // GAIN, YOU CAN PUT GAIN NUMBER HERE TO CUSTOMIZE
            concMeasurement = convertVoltToConc(volt: voltsMeasurementTest, slope: calibration!.slope, yint: calibration!.yint, concStandard: calibration!.concStandard)
            // Display on the temp label
            //NSNotificationCenter.defaultCenter().postNotificationName("updateTimer", object: nil)
            //mVLabel.text = "\(voltsMeasurementTest) mV"
            //mMLabel.text = "\(round(100*concMeasurement)/100) mM"
            self.mVLabel.text = "\(round(10*voltsMeasurementTest)/10) mV"
            self.mMLabel.text = "\(round(10*concMeasurement)/10) mM"
            timeArray.append(minutes-initialMinutes)
            if timeArray.count == 1 {
                initialMinutes = timeArray[0]
                timeArray[0] = minutes-initialMinutes
            }
            minutesArray.append(String(round(100*(minutes-initialMinutes)/100)))
            voltArray.append(voltsMeasurementTest)
            concArray.append(round(100*concMeasurement)/100)
            print(dataBytes)
            print(timeArray)
            print(voltsMeasurementTest)
            print(voltArray)
            print(concMeasurement)
            print(concArray)
            
            // SET CHART DATA
            
            //creates an array of data entries
            var yValues : [ChartDataEntry] = [ChartDataEntry]()
            
            for i in 0..<concArray.count {
               yValues.append(ChartDataEntry(x: Double(i), y: concArray[i]));
            }
            
            //create a data set with array
            let ySet: LineChartDataSet = LineChartDataSet(values: yValues, label: "")
            
            // line chart config
            ySet.axisDependency = .left
            ySet.setColor(UIColor.blue)
            ySet.setCircleColor(UIColor.blue)
            ySet.lineWidth = 2.0
            ySet.circleRadius = 3.0
            ySet.drawCircleHoleEnabled = false
            ySet.drawFilledEnabled = false
            
            //create an array to store LineChartDataSets
            var dataSets : [LineChartDataSet] = [LineChartDataSet]()
            dataSets.append(ySet)
            
            let data: LineChartData = LineChartData(dataSets: dataSets)

            // finally set data
            self.experimentChartView.data = data
            
        }
    }
    
    // If disconnected, show disconnected
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.statusLabel.text = "Disconnected"
        self.mVLabel.text = "0.00 mV"
        self.mMLabel.text = "0.00 mM"
        //central.scanForPeripheralsWithServices(nil, options: nil)
    }
    
    // ------- EMAIL ----------
    
    @IBAction func emailButtonAction(sender: AnyObject) {
        let mailComposeViewController = configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let currentDateTime = NSDate()
        let formatter = DateFormatter()
        formatter.timeStyle = DateFormatter.Style.short
        formatter.dateStyle = DateFormatter.Style.short
        let stringDate = formatter.string(from: currentDateTime as Date)
        
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        mailComposerVC.setSubject("Session Results - "+stringDate)
        mailComposerVC.setMessageBody("Write session details here (e.g., subject name; session location; calibration input parameters; calibration curve's slope, y-intercept, correlation, etc.)", isHTML: false)
        
        tupleMaxArrayString = [String](repeating: "", count: maxSize+2)
        
        for i in 0...timeDict.count {
            var timeString = timeDict["Experiment \(i)"].flatMap{String(describing: $0)}
            if timeString != nil {
                timeString!.remove(at: timeString!.startIndex)
                timeString!.remove(at: timeString!.index(before: timeString!.endIndex))
                var timeArrayString = timeString!.components(separatedBy: ", ")
                timeMaxArrayString = [String](repeating: "", count: maxSize)
                timeMaxArrayString[0..<timeArrayString.count] = timeArrayString[0..<timeArrayString.count]
                timeMaxArrayString.insert("time (min)", at: 0)
                timeMaxArrayString.insert("Experiment \(i)", at: 0)
                
                var voltString = voltDict["Experiment \(i)"].flatMap{String(describing: $0)}
                voltString!.remove(at: voltString!.startIndex)
                //voltString!.remove(at: voltString!.endIndex(before:))
                voltString!.remove(at: voltString!.index(before: voltString!.endIndex))
                var voltArrayString = voltString!.components(separatedBy: ", ")
                voltMaxArrayString = [String](repeating: "", count: maxSize)
                voltMaxArrayString[0..<voltArrayString.count] = voltArrayString[0..<voltArrayString.count]
                voltMaxArrayString.insert("voltage (mV)", at: 0)
                voltMaxArrayString.insert("", at: 0)
                
                var concString = concDict["Experiment \(i)"].flatMap{String(describing: $0)}
                concString!.remove(at: concString!.startIndex)
                concString!.remove(at: concString!.index(before: concString!.endIndex))
                var concArrayString = concString!.components(separatedBy: ", ")
                concMaxArrayString = [String](repeating: "", count: maxSize)
                concMaxArrayString[0..<concArrayString.count] = concArrayString[0..<concArrayString.count]
                concMaxArrayString.insert("concentration (mM)", at: 0)
                concMaxArrayString.insert("", at: 0)
                
                for j in 0..<maxSize+2 {
                    tupleMaxArrayString[j] = tupleMaxArrayString[j]+","+timeMaxArrayString[j]+","+voltMaxArrayString[j]+","+concMaxArrayString[j]
                }
            }
        }
        
        let joinedString = tupleMaxArrayString.joined(separator: "\n")
        print(joinedString)
        if let data = (joinedString as NSString).data(using: String.Encoding.utf8.rawValue){
            mailComposerVC.addAttachmentData(data, mimeType: "text/csv", fileName: "SessionResults_"+stringDate+".csv")
        }
        
        return mailComposerVC
    }
    
    func showSendMailErrorAlert() {
        let alertController = UIAlertController(title: "Error", message: "Device cannot send email ", preferredStyle: .alert)
        self.present(alertController, animated: true, completion:nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result.rawValue {
        case MFMailComposeResult.cancelled.rawValue:
            print("Mail cancelled")
        case MFMailComposeResult.saved.rawValue:
            print("Mail saved")
        case MFMailComposeResult.sent.rawValue:
            print("Mail sent")
            experiment.emailBool = true
        case MFMailComposeResult.failed.rawValue:
            print("Mail sent failure: \(error!.localizedDescription)")
        default:
            break
        }
        controller.dismiss(animated: false, completion: nil)
    }
    
    // -------CHARTS -----
    
    // Function containing chart configuration based on the third-party Charts framework. These can be changed to your convenience.
    func configureChart() {
        //Chart config
        experimentChartView.leftAxis.axisMinimum = 0
        //experimentChartView.leftAxis.labelCount = 5
        //experimentChartView.leftAxis.valueFormatter = NSNumberFormatter()
        //experimentChartView.leftAxis.valueFormatter?.minimumFractionDigits = 1
        experimentChartView.leftAxis.valueFormatter = DefaultAxisValueFormatter(decimals: 1)
        experimentChartView.chartDescription?.text = ""
        experimentChartView.noDataText = "No Data"
        experimentChartView.dragEnabled = true
        experimentChartView.rightAxis.enabled = false
        experimentChartView.doubleTapToZoomEnabled = true
        experimentChartView.pinchZoomEnabled = true
        experimentChartView.legend.enabled = false
        experimentChartView.drawBordersEnabled = true
        //Configure xAxis
        let chartXAxis = experimentChartView.xAxis as XAxis
        chartXAxis.labelPosition = .bottom
    }
    
    
}
