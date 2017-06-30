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
import Charts

/**
 *  Calibrate the system in real time.
 *
 */
class RealTimeCalibrateViewController: UIViewController,
    CBCentralManagerDelegate, CBPeripheralDelegate {
    
    
    /** Charts Related Outlets. */
    @IBOutlet weak var realTimeChart: LineChartView!
    @IBOutlet weak var voltChartLabel: UILabel!
    
    
    /** -- Declare Variables and Outlets. */
    let calibration = Calibration()
    var patientID: String!
    var dataCounter : Int = 0
    var concStandardValue: Double = 0
    var concValue: Double = 0
    var voltValue: Double = 0
    var initialMinutes: Double = 0
    var voltArray = [Double]()
    var stableVoltArray = [Double]()
    var concStandardValueString: String = ""
    var concValueString: String = ""
    var voltValueString: String = ""
    var timeArray = [Double]()
    var minutesArray = [String]()
    var timeForLoop: Double = 60.0
    var timeCounter: Double = 0.0
    var range: Double = 10.0
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
    @IBOutlet weak var rangeLabel: UILabel!
    @IBOutlet weak var enterRangeValue: UITextField!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var enterTimeField: UITextField!

    
    var launchBool: Bool = false {
        didSet {
            if launchBool == true {
                self.startRun.setTitle("Running", for: .normal)
                self.centralManager = CBCentralManager(delegate: self, queue: nil)
                self.startTime()
            } else {
                if self.sensorPeripheral != nil {
                    self.stopScan()
                    self.startRun.setTitle("Start", for: .normal)
                    self.sensorPeripheral?.setNotifyValue(false, for: thisCharacteristic!)
                    self.centralManager.cancelPeripheralConnection(sensorPeripheral!)
                    self.getVoltValue()
                    self.voltLabel.text = (NSString(format: "%.2f", voltValue) as String)
                    self.controlView.backgroundColor = UIColor.green
                    self.controlViewLabel.text = "READY"
                } else {
                    self.stopScan()
                    self.startRun.setTitle("Start", for: .normal)
                    self.statusLabel.text = "Peripheral not advertising properly, try again"
                }
            }
        }
    }

    //--- Main/Segue functions -----//
    
    /**
     * When view loads, set the hiddens and configure the chart.
     *
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        setHiddens()
        voltChartLabel.transform = CGAffineTransform (rotationAngle: CGFloat(-M_PI_2))
        configureChart()
    }

    /**
     * Allow user to go to another view controller.
     *
     */
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "realtimeToCalibration" {
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
        return true
    }
    
    /**
     * Prepare for segue.
     *
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.updateCalibration()
        if (segue.identifier == "realtimeToCalibration") {
            let tabBarViewController = segue.destination as! UITabBarController
            let firstViewController = tabBarViewController.viewControllers![0] as! CalibrationViewController
            let secondViewController = tabBarViewController.viewControllers![1] as! ExperimentViewController
            firstViewController.calibration = calibration
            secondViewController.calibration = calibration
            secondViewController.patientID = self.patientID
        }
    }

    /**
     * Handle enterring the reference concentration.  Send an error if none is sent over.
     *
     */
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

    /**
     * Handle stuff when start is pressed.  This is when the actual calibration and bluetooth stuff shoudl come on.
     *
     */
    @IBAction func startisPressed(_ sender: Any) {
        if (Double(self.enterConcValueTextField.text!) != nil) {
            if (Double(self.enterRangeValue.text!) != nil) {
                self.range = Double(self.enterRangeValue.text!)!
            }
            if (Double(self.enterTimeField.text!) != nil) {
                self.timeForLoop = Double(self.enterTimeField.text!)!
            }
            self.timeCounter = 0.0
            self.stableVoltArray.removeAll()
            self.voltArray.removeAll()
            self.timeArray.removeAll()
            self.initialMinutes = 0
            self.controlView.backgroundColor = UIColor.red
            self.controlViewLabel.text = "WAIT"
            self.concValue = Double(self.enterConcValueTextField.text!)!
            self.launchBool = !self.launchBool
        } else {
            let alert = UIAlertController(title: "Alert", message: "Please enter valid concentration", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
        }
    }

    /**
     * When enter is pressed, enter the values into the concentration value string and volt value string.
     *
     */
    @IBAction func enterIsPressed(_ sender: Any) {
        if (controlView.backgroundColor == UIColor.green) {
            dataCounter += 1
            concValueString += String(concValue) + " "
            voltValueString += voltLabel.text! + " "
            voltLabel.text = "";
            enterConcValueTextField.text = "";
            concValue = 0;
            voltValue = 0;
            voltArray.removeAll()
            self.range = 10.0
            self.timeForLoop = 60.0
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

    /**
     * Gets the voltage value.
     *
     */
    func getVoltValue() {
        var average: Double = 0
        for volt in self.stableVoltArray {
            average += volt
        }
        self.voltValue = average / Double(self.stableVoltArray.count)
    }

    /**
     * Updates the calibration information.
     *
     */
    func updateCalibration() {
        self.calibration.concStandardText = self.concStandardValueString
        self.calibration.concStandard = self.concStandardValue
        self.calibration.concText = self.concValueString.substring(to: self.concValueString.endIndex)
        self.calibration.voltText = self.voltValueString.substring(to: self.voltValueString.endIndex)
    }
    
    /**
     * Set hiddens before ref concentration value is entered.
     *
     */
    func setHiddens() {
        self.enterConcValue.isHidden = true
        self.enterConcValueTextField.isHidden = true
        self.enterVoltLabel.isHidden = true
        self.voltView.isHidden = true
        self.voltLabel.isHidden = true
        self.startRun.isHidden = true
        self.controlView.isHidden = true
        self.controlViewLabel.isHidden = true
        self.enterRun.isHidden = true
        self.calibrateButton.isHidden = true
        self.refValueLabel.isHidden = false
        self.refValueTextField.isHidden = false
        self.enterRefValue.isHidden = false
        self.realTimeChart.isHidden = true
        self.voltChartLabel.isHidden = true
        self.rangeLabel.isHidden = true
        self.enterRangeValue.isHidden = true
        self.enterTimeField.isHidden = true
        self.timeLabel.isHidden = true
    }
    
    /**
     * Set things not hidden after ref concentration value is entered.
     *
     */
    func setNotHiddens() {
        self.enterConcValue.isHidden = false
        self.enterConcValueTextField.isHidden = false
        self.enterVoltLabel.isHidden = false
        self.voltView.isHidden = false
        self.voltLabel.isHidden = false
        self.startRun.isHidden = false
        self.controlView.isHidden = false
        self.controlViewLabel.isHidden = false
        self.enterRun.isHidden = false
        self.calibrateButton.isHidden = false
        self.refValueLabel.isHidden = true
        self.refValueTextField.isHidden = true
        self.enterRefValue.isHidden = true
        self.realTimeChart.isHidden = false
        self.voltChartLabel.isHidden = false
        self.rangeLabel.isHidden = false
        self.enterRangeValue.isHidden = false
        self.enterTimeField.isHidden = false
        self.timeLabel.isHidden = false
        
    }
    
    /**
     * Checks the volt value.  If new value is in the given range, add it to stable volt array.
     * Still add to general volt array to display on graph,.
     *
     */
    func checkVoltValue(voltTest: Double) {
        if self.stableVoltArray.count >= 1 {
            let previousValue = self.stableVoltArray[self.stableVoltArray.count - 1]
            let difference = abs(previousValue - voltTest)
            print(difference)
            if (difference < self.range) {
                self.stableVoltArray.append(voltTest)
            } else {
                self.stableVoltArray.removeAll()
                self.timeCounter = 0.0
            }
        } else if self.stableVoltArray.count == 0 {
            self.stableVoltArray.append(voltTest)
        }
        
        print(self.timeCounter)
        self.voltArray.append(voltTest)
        self.displayPlot()
    }
    
    /**
     * Start the timer.  Checks every 1 second and looks at checkFullTime, which increments the time counter and checks
     * if it is 60 seconds.
     *
     */
    func startTime() {
        self.voltTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.checkFullTime), userInfo: nil, repeats: true)
    }
    
    /**
     * Checks the to see if the time counter is equal to 60.  Increments beforehand.
     *
     */
    func checkFullTime() {
        self.timeCounter = self.timeCounter + 1.0
        if (self.timeCounter == self.timeForLoop) {
            self.falseLaunch()
            
        }
    }
    
    /**
     * Set the launch to false, which handles stopping the bluetooth and
     * stopping the run altogether.
     *
     */
    func falseLaunch() {
        self.launchBool = false;
    }
    
    /**
     * Gets the time to append to time arrays.
     *
     */
    func getTimeForArray() {
        let date = NSDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss:SSS"
        let timeStamp = dateFormatter.string(from: date as Date)
        let timeStampStringArray = timeStamp.components(separatedBy: ":")
        let timeStampDoubleOptionalArray = timeStampStringArray.map({NumberFormatter().number(from: $0)?.doubleValue})
        let timeStampDoubleArray = timeStampDoubleOptionalArray.flatMap{$0}
        let seconds = timeStampDoubleArray[2] + timeStampDoubleArray[3]/1000
        let minutes = timeStampDoubleArray[0]*60 + timeStampDoubleArray[1] + seconds/60
        self.timeArray.append(minutes-initialMinutes)
        if self.timeArray.count == 1 {
            self.initialMinutes = self.timeArray[0]
            self.timeArray[0] = minutes - self.initialMinutes
        }
        self.minutesArray.append(String(round(100*(minutes - self.initialMinutes)/100)))
    }

    /* ----- BLUETOOTH FUNCTIONS ------ */
    /** BLE properties */
    var centralManager : CBCentralManager!
    var sensorPeripheral : CBPeripheral?
    
    /** Services and characteristics of interest */
    let adcUUID = "A6322521-EB79-4B9F-9152-19DAA4870418"
    let voltUUID = "F90EA017-F673-45B8-B00B-16A088A2ED62"
    
    
    /**
     * Stops the scan of the experiment.
     *
     */
    func stopScan() {
        self.centralManager.stopScan()
        self.voltTimer?.invalidate()
        self.voltTimer = nil
    }
    
    /**
     * Check status of BLE hardware.
     *
     */
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn && launchBool == true {
            // Scan for peripherals if BLE is turned on
            central.scanForPeripherals(withServices: nil, options: nil)
            self.statusLabel.text = "Searching for BLE Devices"
            print("still running")
        }
        else {
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
                peripheral.discoverCharacteristics(nil, for: thisService)
                print("Works!")
            }
            else {
                print("Did not work")
            }
            print(thisService.uuid)
        }
    }
    
    /**
     * Look for valid characteristics.
     *
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        self.statusLabel.text = "Looking at the service's characteristics"

        // check the uuid of each characteristic to find config and data characteristics
        for characteristic in service.characteristics! {
            thisCharacteristic = characteristic as CBCharacteristic
            if String(describing: thisCharacteristic!.uuid) == voltUUID {
                self.sensorPeripheral?.setNotifyValue(true, for: thisCharacteristic!)
                print("Works!!!")
            }
            print(thisCharacteristic!.uuid)
        }
    }
    
    /**
     * Gets data values when they are updated.
     *
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        self.statusLabel.text = "Connected"
        
        if String(describing: characteristic.uuid) == self.voltUUID {
            
            self.getTimeForArray()

            // Convert NSData to array of signed 16 bit values
            let dataBytes = characteristic.value!
            let dataLength = dataBytes.count / MemoryLayout<UInt8>.size
            var dataArray: [UInt8] = [UInt8](repeating: 0, count: dataLength)
            dataBytes.copyBytes(to: &dataArray, count: dataLength * MemoryLayout<UInt8>.size)
            
            let u16 = UnsafePointer(dataArray).withMemoryRebound(to: UInt16.self, capacity: 1) {
                $0.pointee
            }
            
            let voltsMeasurement = Double(u16)
            let voltsMeasurementTest = voltsMeasurement / (5.78)
            
            self.checkVoltValue(voltTest: voltsMeasurementTest)
        }
    }
    
    /**
     * If the bluetooth is disconnected, update the status label to show that it is disconnected.
     * 
     */
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.statusLabel.text = "Disconnected"
    }
    
    // -------- CHARTS ----------
    
    /**
     * Function handling the display of the plot for the chart.
     *
     */
    func displayPlot() {
        var chartValues : [ChartDataEntry] = [ChartDataEntry]()
        
        for i in 0..<voltArray.count {
            chartValues.append(ChartDataEntry(x: timeArray[i], y: voltArray[i]))
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
        
        self.realTimeChart.data = data
    }
    
    
    /**
     * Function contiaining chart configuration based on the third-party Charts framework.
     *
     */
    func configureChart() {
        self.realTimeChart.leftAxis.axisMinimum = 0
        self.realTimeChart.xAxis.axisMinimum = 0
        self.realTimeChart.leftAxis.valueFormatter = DefaultAxisValueFormatter(decimals: 1)
        self.realTimeChart.chartDescription?.text = ""
        self.realTimeChart.noDataText = "No Data"
        self.realTimeChart.dragEnabled = true
        self.realTimeChart.rightAxis.enabled = false
        self.realTimeChart.doubleTapToZoomEnabled = true
        self.realTimeChart.pinchZoomEnabled = true
        self.realTimeChart.legend.enabled = false
        self.realTimeChart.drawBordersEnabled = true
        let chartXAxis = realTimeChart.xAxis as XAxis
        chartXAxis.labelPosition = .bottom
    }

}
