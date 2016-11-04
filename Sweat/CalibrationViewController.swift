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
    
    // ----- Classes, properties, and built in functions -----
    // Label variable for calibration fit
    @IBOutlet weak var equationLabel: UILabel!
    //Label variable for coefficent of determination
    @IBOutlet weak var rsquaredLabel: UILabel!
    //View variable for plto showing claibration curve
    @IBOutlet weak var calibrationChartView: LineChartView!
    //Label variable for voltage y-axis label
    @IBOutlet weak var voltageLabel: UILabel!
    
    var calibration: Calibration?
    var experiment = Experiment()
    
    // Built-in function to do stuff when view is loaded.
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // ---------- CALIBRATION PARAMETERS AND FIT RESULTS ----------
        
        // Rotates voltage label 90 degrees so that it looks nice next to the plot.
        voltageLabel.transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI_2))
        
        // Extracts double values of concentration and volt parametes of calibration run by user.
        //let concValues = calibration!.concText.components(separatedBy: " ")
        let concTuple = calibration!.valuesChecker(textField: calibration!.concText)
        let voltTuple = calibration!.valuesChecker(textField: calibration!.voltText)
        let concValuesScaled = calibration!.convertConcToLogConc(standard: calibration!.concStandard, concentration: concTuple.values)
        let voltValues = voltTuple.values
        
        // Takes concentration and voltage values of calibration and runs a least squares regression using the custom function leastSquaresRegression belonging to the Calibration class.
        let equation = calibration!.leastSquaresRegression(concentration: concValuesScaled, voltage: voltTuple.values)
        
        // Assigns results from the function leastSquaresRegression contained by the variable "equation" above to linear fit and rsquared parameters.
        calibration!.slope = equation.slope
        calibration!.yint = equation.yint
        calibration!.rSquared = equation.rSquared
        
        // Rounds calibration fit paramets to the nearest thousandth
        let slopeRounded = round(1000 * calibration!.slope) / 1000
        let yintRounded = round(1000 * calibration!.yint) / 1000
        let rSquaredRounded = round(1000 * calibration!.rSquared) / 1000
        
        // Assigns paramets to equation and rsquared text labels.
        equationLabel.text = "v = \(slopeRounded)c\(yintRounded)"
        rsquaredLabel.text = "R"+"\u{00B2}"+" = "+"\(rSquaredRounded)"
        
        // Shares experiment (instance of Experiment class) between CalibrationViewController and ExperimentViewController.
        let barViewControllers = self.tabBarController?.viewControllers
        let experimentViewControllerReference = barViewControllers![1] as! ExperimentViewController
        experimentViewControllerReference.experiment = self.experiment  //shared model
        
        //Function configures chart.
        configureChart()
        
        // -------- DISPLAYING THE CALIBRATION PLOT -------
        
        //creates an array of data entries to contain volt values
        var yValues : [ChartDataEntry] = [ChartDataEntry]()
        
        //Assigns volt values of calibration to variable yValues.
        for i in 0..<voltValues.count {
            yValues.append(ChartDataEntry(x: voltValues[i], y: Double(i)))
        }
        
        //create a data set with array of voltage values.
        let ySet: LineChartDataSet = LineChartDataSet(values: yValues, label: "")
        
        // line chart configuration.
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

        //Data object that has all data corresponding to the calibration plot
        let data: LineChartData = LineChartData(dataSets: dataSets)
        
        // Passes the concentration (x) and voltage (y) calibration data to the property data of calibrationChartView.
        self.calibrationChartView.data = data
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // ------ SEGUE FUNCTIONS -----
    
    // Function determines whether the segue with the specified identifier should be performed.
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        // calibrationAlert1 variable corresponding to instructions if current experiment is running and the user wants to go back to the calibrate view.
        let calibrationAlert1 = UIAlertController(title: "Alert", message: "Please stop current experiment to start new session or view last session", preferredStyle: .alert)
        // calibrationAlert2 variable corresponding to warning for user that experiment data has not been saved. Data should be emailed from experiment view to not lose data captured.
        let calibrationAlert2 = UIAlertController(title: "Alert", message: "You have data that hasn't been emailed. All data will be lost. Do you wish to proceed?", preferredStyle: .alert)
        // Six lines below correspond to alert setup
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        let yesAction = UIAlertAction(title: "Yes", style: .default, handler: {[weak self](action) -> Void in self?.performSegue(withIdentifier: "recalibrateSegue", sender: self)})
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        calibrationAlert1.addAction(okAction)
        calibrationAlert2.addAction(yesAction)
        calibrationAlert2.addAction(cancelAction)
        
        // Conditions for the two different alerts to pop up for user based on launchBool (a property of the Experiment class)
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
    
    // -------- CHARTS ----------
    
    // Function contiaining chart configuration based on the third-party Charts framework.
    func configureChart() {
        //Chart config
        calibrationChartView.leftAxis.axisMinimum = 0
        calibrationChartView.xAxis.axisMinimum = 0
        calibrationChartView.leftAxis.valueFormatter = DefaultAxisValueFormatter(decimals: 1)
        calibrationChartView.chartDescription?.text = ""
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
