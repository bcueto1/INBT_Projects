//
//  CalibrationViewController.swift
//  Sweat
//
//  Created by Brian Cueto on 10/25/16.
//  Copyright © 2016 Brian_INBT. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth
import Charts

class CalibrationViewController: UIViewController, ChartViewDelegate {
    
    @IBOutlet weak var equationLabel: UILabel!
    
    @IBOutlet weak var rsquaredLabel: UILabel!
    
    @IBOutlet weak var calibrationChartView: LineChartView!
    
    
    @IBOutlet weak var voltageLabel: UILabel!
    
    var calibration: Calibration?
    var experiment = Experiment()
    //var centralManager: CBCentralManager?
    
    /*
     let concStandard = Double(calibration.concStandard!) ?? 1000
     let concTuple = calibration.valuesChecker(concTextField.text)
     let voltTuple = valuesChecker(voltTextField.text)
     let concValuesScaled = convertConcToLogConc(concStandard, concentration: concTuple.values)
     let equation = leastSquaresRegression(concValuesScaled, voltage: voltTuple.values)
     let slopeRounded = round(1000 * equation.slope) / 1000
     let yintRounded = round(1000 * equation.yint) / 1000
     let rSquaredRounded = round(1000 * equation.rSquared) / 1000
     destinationVC.equationLabelText = "v = \(slopeRounded)c\(yintRounded)"
     destinationVC.rsquaredLabelText = "R"+"\u{00B2}"+" = "+"\(rSquaredRounded)"
     */
    
    
    /*
     var concStandard: Double = 0
     var slope: Double = 0
     var yint: Double = 0
     
     var equationLabelText: String = ""
     var rsquaredLabelText: String = ""
     */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        voltageLabel.transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI_2))
        let concValues = calibration!.concText.components(separatedBy: " ")
        let concTuple = calibration!.valuesChecker(textField: calibration!.concText)
        let voltTuple = calibration!.valuesChecker(textField: calibration!.voltText)
        let concValuesScaled = calibration!.convertConcToLogConc(standard: calibration!.concStandard, concentration: concTuple.values)
        let voltValues = voltTuple.values
        let equation = calibration!.leastSquaresRegression(concentration: concValuesScaled, voltage: voltTuple.values)
        calibration!.slope = equation.slope
        calibration!.yint = equation.yint
        calibration!.rSquared = equation.rSquared
        let slopeRounded = round(1000 * calibration!.slope) / 1000
        let yintRounded = round(1000 * calibration!.yint) / 1000
        let rSquaredRounded = round(1000 * calibration!.rSquared) / 1000
        equationLabel.text = "v = \(slopeRounded)c\(yintRounded)"
        rsquaredLabel.text = "R"+"\u{00B2}"+" = "+"\(rSquaredRounded)"
        //let barViewControllers = self.tabBarController?.viewControl
        //let tabBarController = UITabBarController()
        //let experimentViewControllerReference = tabBarController.viewControllers![1] as! ExperimentViewController
        
        let barViewControllers = self.tabBarController?.viewControllers
        let experimentViewControllerReference = barViewControllers![1] as! ExperimentViewController
        experimentViewControllerReference.experiment = self.experiment  //shared model
        
        configureChart()
        
        // NECESSARY?
        
        //let concMutableArray = NSMutableArray()
        //let voltMutableArray = NSMutableArray()
        
        //concValuesScaled = concMutableArray as NSArray as! [Double]
        //voltValues = voltMutableArray as NSArray as! [Double]
        
        // SET DATA
        
        //creates an array of data entries
        var yValues : [ChartDataEntry] = [ChartDataEntry]()
        
        for i in 0..<voltValues.count {
            yValues.append(ChartDataEntry(x: voltValues[i], y: Double(i)))
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
        self.calibrationChartView.data = data
    }
    
    /*
     override func viewWillAppear(animated: Bool) {
     // Updates the view controller interface using the updated model
     let slopeRounded = round(1000 * calibration!.slope) / 1000
     let yintRounded = round(1000 * calibration!.yint) / 1000
     let rSquaredRounded = round(1000 * calibration!.rSquared) / 1000
     equationLabel.text = "v = \(slopeRounded)c\(yintRounded)"
     rsquaredLabel.text = "R"+"\u{00B2}"+" = "+"\(rSquaredRounded)"
     equationLabel.text = "v = \(slopeRounded)c\(yintRounded)"
     rsquaredLabel.text = "R"+"\u{00B2}"+" = "+"\(rSquaredRounded)"
     
     }*/
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        // ALERT CODE
        let calibrationAlert1 = UIAlertController(title: "Alert", message: "Please stop current experiment to start new session or view last session", preferredStyle: .alert)
        let calibrationAlert2 = UIAlertController(title: "Alert", message: "You have data that hasn't been emailed. All data will be lost. Do you wish to proceed?", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        let yesAction = UIAlertAction(title: "Yes", style: .default, handler: {[weak self](action) -> Void in self?.performSegue(withIdentifier: "recalibrateSegue", sender: self)})
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        calibrationAlert1.addAction(okAction)
        calibrationAlert2.addAction(yesAction)
        calibrationAlert2.addAction(cancelAction)
        
        //calibrationAlert.addAction(cancelAction)
        if  experiment.launchBool == true {
            present(calibrationAlert1, animated: true, completion: nil)
            return false
        } else if experiment.emailBool == false {
            present(calibrationAlert2, animated: true, completion: nil)
            return false
        } else {
            return true
        }
    }
    
    /* IMPLEMENT ALERT IF TRYING TO GO HOME WHILE EXPERIMENT IS RUNNING
     override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject!) -> Bool {
     // ALERT CODE
     let calibrationAlert = UIAlertController(title: "Alert", message: "Please stop current session", preferredStyle: .Alert)
     let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
     //let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
     calibrationAlert.addAction(okAction)
     //calibrationAlert.addAction(cancelAction)
     if experimentViewControllerReference.check == false && experimentViewControllerReference.launchBool == true {
     presentViewController(calibrationAlert, animated: true, completion: nil)
     return false
     } else {
     return true
     }
     }
     */
    
    
    /*
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     if (segue.identifier == "calibrationSegue") {
     // Get a reference to the destination view controller
     let destinationViewController: ExperimentViewController = segue.destinationViewController as! ExperimentViewController
     destinationViewController.calibration = calibration
     destinationViewController.centralManager = centralManager
     }
     }
     */
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    // CUSTOM FUNCTIONS
    
    
    /*
     func calibrator() -> (equationLabelText: String, rsquaredLabelTextString {
     let calibration = Calibration()
     let concStandard = Double(calibration.concStandard!) ?? 1000
     let concTuple = calibration.valuesChecker(calibration.conc)
     let voltTuple = calibration.valuesChecker(calibration.volt)
     let concValuesScaled = calibration.convertConcToLogConc(concStandard, concentration: concTuple.values)
     let equation = calibration.leastSquaresRegression(concValuesScaled, voltage: voltTuple.values)
     let slopeRounded = round(1000 * equation.slope) / 1000
     let yintRounded = round(1000 * equation.yint) / 1000
     
     
     }
     */
    
    // CHARTS
    
    func configureChart() {
        //Chart config
        calibrationChartView.leftAxis.axisMinimum = 0
        calibrationChartView.xAxis.axisMinimum = 0
        //calibrationChartView.leftAxis.valueFormatter = NumberFormatter()
        //calibrationChartView.leftAxis.valueFormatter?.minimumFractionDigits = 1
        
        calibrationChartView.leftAxis.valueFormatter = DefaultAxisValueFormatter(decimals: 1)
        calibrationChartView.chartDescription?.text = ""
        
        //calibrationChartView.noDataTextDescription = "No Data"
        calibrationChartView.noDataText = "No Data"
        calibrationChartView.dragEnabled = true
        calibrationChartView.rightAxis.enabled = false
        calibrationChartView.doubleTapToZoomEnabled = true
        calibrationChartView.pinchZoomEnabled = true
        calibrationChartView.legend.enabled = false
        calibrationChartView.drawBordersEnabled = true
        //Configure xAxis
        let chartXAxis = calibrationChartView.xAxis as XAxis
        chartXAxis.labelPosition = .bottom
    }
}
