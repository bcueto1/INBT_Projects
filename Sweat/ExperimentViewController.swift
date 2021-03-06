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

/**
 * Experiment view controller where person can test concentration values vs. time.
 *
 */
class ExperimentViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, MFMailComposeViewControllerDelegate, ChartViewDelegate {
    
    /** Outlets */
    @IBOutlet weak var concentrationLabel: UILabel!
    @IBOutlet weak var experimentChartView: LineChartView!
    @IBOutlet weak var connectButtonOutlet: UIButton!
    @IBAction func connectButtonAction(sender: UIButton) {
        launchBool = !launchBool
        experiment.launchBool = launchBool
        
    }
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var mVLabel: UILabel!
    @IBOutlet weak var mMLabel: UILabel!
    @IBOutlet weak var rangeText: UITextField!
    @IBOutlet weak var stableTimeField: UITextField!
    @IBOutlet weak var measurementTimeField: UITextField!
    
    //Lists the proper concentration and time when appropriate
    @IBOutlet weak var stableConcentration: UILabel!
    @IBOutlet weak var measurementConcentration: UILabel!
    
    /** Variables */
    var calibration: Calibration?
    var experiment = Experiment()
    var patientID: String!
    var experimentNumber: Int?
    var bluetoothBool = false
    var timeCounter: Double = 0.0
    var timer: Timer?
    var thisCharacteristic: CBCharacteristic?
    var initialMinutes: Double = 0
    var maxSize: Int = 0
    var range: Double = 1.0
    var testStable: Bool = true
    var measurementTimeLimitReached: Bool = false
    var stableTimeLimit: Double = 60.0
    var measurementTimeLimit: Double = 60.0
    var timeDict = [String:[Double]]()
    var voltDict = [String:[Double]]()
    var concDict = [String:[Double]]()
    var timeDictString = [String:[String]]()
    var voltDictString = [String:[String]]()
    var concDictString = [String:[String]]()
    var timeArray = [Double]()
    var minutesArray = [String]()
    var voltArray = [Double]()
    var concArray = [Double]()
    var stableConcValue: Double = 0.0
    var stableConcArray = [Double]()
    var measurementConcValue: Double = 0.0
    var measurementConcArray = [Double]()
    var averageStableArray = [Double]()
    var averageMeasurementArray = [Double]()
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

    /**
     * Handle setting bluetooth functioanlity to run or not.
     *
     */
    var launchBool: Bool = false {
        didSet {
            if launchBool == true {
                if (self.rangeText.text != "") {
                    self.range = Double(self.rangeText.text!)!
                }
                if (self.stableTimeField.text != "") {
                    self.stableTimeLimit = Double(self.stableTimeField.text!)!
                }
                if (self.measurementTimeField.text != "") {
                    self.measurementTimeLimit = Double(self.measurementTimeField.text!)!
                }
                connectButtonOutlet.setTitle("Stop Experiment \(experimentNumber!)", for: .normal)
                centralManager = CBCentralManager(delegate: self, queue: nil)
                experimentNumber! += 1
                self.startTime()
                
            } else {
                if self.sensorPeripheral != nil {
                    self.stopScan()
                    timeDict["Experiment \(experimentNumber!-1)"] = timeArray
                    voltDict["Experiment \(experimentNumber!-1)"] = voltArray
                    concDict["Experiment \(experimentNumber!-1)"] = concArray
                    if timeArray.count > maxSize {
                        maxSize = timeArray.count
                    }
                    self.averageStableArray.append(self.stableConcValue)
                    self.averageMeasurementArray.append(self.measurementConcValue)
                    self.initialMinutes = 0
                    self.minutesArray.removeAll()
                    self.timeArray.removeAll()
                    self.voltArray.removeAll()
                    self.concArray.removeAll()
                    self.stableConcArray.removeAll()
                    self.stableConcValue = 0.0
                    self.measurementConcArray.removeAll()
                    self.measurementConcValue = 0.0
                    self.timeCounter = 0.0
                    self.range = 1.0
                    self.stableTimeLimit = 60.0
                    self.measurementTimeLimit = 60.0
                    self.testStable = true
                    self.measurementTimeLimitReached = false
                    self.stableConcentration.text = ""
                    self.measurementConcentration.text = ""
                    experiment.emailBool = false
                    print(voltDict)
                    connectButtonOutlet.setTitle("Start Experiment \(experimentNumber!)", for: .normal)
                    self.sensorPeripheral?.setNotifyValue(false, for: thisCharacteristic!)
                    self.centralManager.cancelPeripheralConnection(sensorPeripheral!)
                    
                } else {
                    self.stopScan()
                    initialMinutes = 0
                    minutesArray.removeAll()
                    timeArray.removeAll()
                    self.voltArray.removeAll()
                    self.concArray.removeAll()
                    self.stableConcArray.removeAll()
                    self.stableConcValue = 0.0
                    self.measurementConcArray.removeAll()
                    self.measurementConcValue = 0.0
                    self.timeCounter = 0.0
                    self.range = 1.0
                    self.stableTimeLimit = 60.0
                    self.measurementTimeLimit = 60.0
                    self.testStable = true
                    self.measurementTimeLimitReached = false
                    self.stableConcentration.text = ""
                    self.measurementConcentration.text = ""
                    experimentNumber! -= 1
                    stopScan()
                    connectButtonOutlet.setTitle("Start Experiment \(experimentNumber!)", for: .normal)
                    self.statusLabel.text = "Peripheral not advertising properly, try again"
                }
            }
        }
    }
    
    /**
     * Do things when the view loads.
     *
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        concentrationLabel.transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI_2))
        experimentNumber = 1
        configureChart()
    }
    
    // -------- Custom Functions ----------
    
    /**
     * Converts volt values to concentration values.
     *
     */
    func convertVoltToConc(volt: Double, slope: Double, yint: Double, concStandard: Double) -> Double {
        let exponent = (volt - yint) / slope
        let conc = concStandard * pow(10.0,exponent)
        return conc
    }
    
    /**
     * Start the timer.  Checks every 1 second and looks at checkFullTime, which increments the time counter and checks
     * if it is 60 seconds.
     *
     */
    func startTime() {
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.checkFullTime), userInfo: nil, repeats: true)
    }
    
    /**
     * Checks the to see if the time counter is equal to 60.  Increments beforehand.
     *
     */
    func checkFullTime() {
        self.timeCounter = self.timeCounter + 1.0
        if ((self.timeCounter == self.stableTimeLimit) && self.testStable) {
            self.updateStable()
            self.timeCounter = 0.0
            self.testStable = false
        } else if ((self.timeCounter >= self.measurementTimeLimit) && !self.testStable) {
            self.updateMeasurement()
        }
    }
    
    /**
     * Update the average stable value.
     *
     */
    func updateStable() {
        var average: Double = 0.0
        for conc in self.stableConcArray {
            average += conc
        }
        self.stableConcValue = average / Double(self.stableConcArray.count)
        self.stableConcentration.text = (NSString(format: "%.2f", self.stableConcValue) as String) + " mM"
        
    }
   
    /**
     * Update the average measurement value.
     *
     */
    func updateMeasurement() {
        var average: Double = 0.0
        for conc in self.measurementConcArray {
            average += conc
        }
        self.measurementConcValue = average / Double(self.measurementConcArray.count)
        self.measurementConcentration.text = (NSString(format: "%.2f", self.measurementConcValue) as String) + " mM"
    }
    
    
    // ----------- Segue Functions ----------
    
    /**
     * Check to see if it is okay to go to another view.
     *
     */
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
    
    /** BLE properties */
    var centralManager : CBCentralManager!
    var sensorPeripheral : CBPeripheral?

    /** Services and characteristics of interest */
    let adcUUID = "A6322521-EB79-4B9F-9152-19DAA4870418"
    let voltUUID = "F90EA017-F673-45B8-B00B-16A088A2ED62"

    func stopScan() {
        self.centralManager.stopScan()
        timer?.invalidate()
        timer = nil
    }

    /**
     * Check status of BLE hardware.
     *
     */
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn && launchBool == true {
            // Scan for peripherals if BLE is turned on
            central.scanForPeripherals(withServices: nil, options: nil)
            //print("cool timer start")
            self.statusLabel.text = "Searching for BLE Devices"
            print("still running")
        }
        else {
            // Can have different conditions for all states if needed - print generic message for now
            print("Bluetooth switched off or not initialized")
        }
    }

    /**
     * Check out the discovered peripherals to find sensor.
     *
     */
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

    /**
     * Discover services of the peripheral.
     *
     */
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.statusLabel.text = "Discovering peripheral services"
        peripheral.discoverServices(nil)
    }
    
    
    /**
     * Check if the service discovered is a valid adc service.
     *
     */
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
    
    
    /**
     * Look for valid volt values.
     *
     */
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
    
    /**
     * Update values whenever a new value is detected.
     *
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        statusLabel.text = "Connected"
        
        if String(describing: characteristic.uuid) == voltUUID {
            
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
            
            // Convert NSData to array of signed 16 bit values
            let dataBytes = characteristic.value!
            let dataLength = dataBytes.count / MemoryLayout<UInt8>.size
            var dataArray = [UInt8](repeating: 0, count: dataLength)
            dataBytes.copyBytes(to: &dataArray, count: dataLength * MemoryLayout<Int8>.size)
            
            let u16 = UnsafePointer(dataArray).withMemoryRebound(to: UInt16.self, capacity: 1) {
                $0.pointee
            }
            voltsMeasurement = Double(u16)
            voltsMeasurementTest = voltsMeasurement / (5.78) // GAIN
            concMeasurement = convertVoltToConc(volt: voltsMeasurementTest, slope: calibration!.slope, yint: calibration!.yint, concStandard: calibration!.concStandard)
            self.mVLabel.text = String(round(100*voltsMeasurementTest)/100) + " mV"
            self.mMLabel.text = String(round(100*concMeasurement)/100) + " mM"
            timeArray.append(minutes-initialMinutes)
            if timeArray.count == 1 {
                initialMinutes = timeArray[0]
                timeArray[0] = minutes-initialMinutes
            }
            minutesArray.append(String(round(100*(minutes-initialMinutes)/100)))
            voltArray.append(voltsMeasurementTest)
            concArray.append(round(100*concMeasurement)/100)
            
            if (self.testStable) {
                self.checkConcValue(concTest: round(100*concMeasurement)/100)
            } else {
                self.addMeasurementConcValue(concTest: round(100*concMeasurement)/100)
            }
            
            self.displayPlot()
        }
    }
    
    /**
     * Checks the volt value.  If new value is in the given range, add it to stable volt array.
     * Still add to general volt array to display on graph,.
     *
     */
    func checkConcValue(concTest: Double) {
        if self.stableConcArray.count >= 1 {
            let previousValue = self.stableConcArray[self.stableConcArray.count - 1]
            let difference = abs(previousValue - concTest)
            print(difference)
            if (difference < self.range) {
                self.stableConcArray.append(concTest)
            } else {
                self.stableConcArray.removeAll()
                self.timeCounter = 0.0
            }
        } else if self.stableConcArray.count == 0 {
            self.stableConcArray.append(concTest)
        }
        print(self.timeCounter)

    }
    
    /**
     * Add value to measurement concentration array.
     *
     */
    func addMeasurementConcValue(concTest: Double) {
        self.measurementConcArray.append(concTest)
        print(self.timeCounter)
    }
    
    /**
     * Displays plot.
     *
     */
    func displayPlot() {
        var chartValues : [ChartDataEntry] = [ChartDataEntry]()
        
        for i in 0..<concArray.count {
            chartValues.append(ChartDataEntry(x: timeArray[i], y: concArray[i]))
        }
        
        let chartSet: LineChartDataSet = LineChartDataSet(values: chartValues, label: "")
        
        chartSet.axisDependency = .left
        chartSet.setColor(UIColor.blue)
        chartSet.setCircleColor(UIColor.blue)
        chartSet.lineWidth = 2.0
        chartSet.circleRadius = 3.0
        chartSet.drawCircleHoleEnabled = false
        chartSet.drawFilledEnabled = false
        
        var dataSets : [LineChartDataSet] = [LineChartDataSet]()
        dataSets.append(chartSet)
        let data: LineChartData = LineChartData(dataSets: dataSets)
        self.experimentChartView.data = data
    }
    
    /**
     * If disconnected, say disconnected.
     *
     */
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.statusLabel.text = "Disconnected"
        self.mVLabel.text = "0.00 mV"
        self.mMLabel.text = "0.00 mM"
    }
    
    // ------- EMAIL ----------
    
    /**
     * Launch the email controller if this button is clicked.
     *
     */
    @IBAction func emailButtonAction(sender: AnyObject) {
        let mailComposeViewController = configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    /**
     * Give the mail view controller certain values.
     *
     */
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let currentDateTime = NSDate()
        let formatter = DateFormatter()
        formatter.timeStyle = DateFormatter.Style.short
        formatter.dateStyle = DateFormatter.Style.short
        let stringDate = formatter.string(from: currentDateTime as Date)
        
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        print(self.patientID)
        mailComposerVC.setSubject("Session Results for patient " + self.patientID + " - "+stringDate)
        mailComposerVC.setMessageBody("Write session details here (e.g., subject name; session location; calibration input parameters; calibration curve's slope, y-intercept, correlation, etc.)" + "\n"
            + "Average stable concentration: " + String(describing: self.averageStableArray) + "\n"
            + "Average measurement concentration: " + String(describing: self.averageMeasurementArray), isHTML: false)
        
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
    
    /**
     * Handle errors for mail.
     *
     */
    func showSendMailErrorAlert() {
        let alertController = UIAlertController(title: "Error", message: "Device cannot send email ", preferredStyle: .alert)
        self.present(alertController, animated: true, completion:nil)
    }
    
    /**
     * Print values based on the result of the email.
     *
     */
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
    
    /**
     * Function to configure the chart onto the view.
     *
     */
    func configureChart() {
        //Chart config
        experimentChartView.leftAxis.axisMinimum = 0
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
