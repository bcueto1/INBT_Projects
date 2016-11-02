//
//  Calibration.swift
//  Sweat
//
//  Created by Brian Cueto on 10/24/16.
//  Copyright © 2016 Brian_INBT. All rights reserved.
//

import Foundation
import UIKit

class Calibration: NSObject {
    
    // CUSTOM VARIABLES
    
    var concStandardText: String = ""  //some text for the concentration standard
    var concText: String = "" //some text for the concentration measured
    var voltText: String = "" //some text for the voltage measured
    var concStandard: Double = 0 //the concentration standard
    var slope: Double = 0 //slope of the calibration
    var yint: Double = 0 //y?
    var rSquared: Double = 0 //Some stat stuff
    
    /*
     init(concStandard: String?, conc: String?, volt: String?) {
     self.concStandard = concStandard
     self.conc = conc
     self.volt = volt
     }
     */
    
    // CUSTOM FUNCTIONS
    
    func valuesChecker (textField: String?) -> (check: Bool, valuesOptional: [Double?], values: [Double]) {
        let StringValues = textField!.components(separatedBy: " ")
        let DoubleValuesOptional = StringValues.map({NumberFormatter().number(from: $0)?.doubleValue})
        let DoubleValues = DoubleValuesOptional.flatMap{$0}
        let checkCalibration = DoubleValues.count == StringValues.count
        return (checkCalibration, DoubleValuesOptional, DoubleValues)
    }
    
    func convertConcToLogConc(standard: Double, concentration: [Double]) -> [Double] {
        let concValuesScaled = concentration.map({log10($0 / standard)})
        return concValuesScaled
    }
    
    func leastSquaresRegression(concentration: [Double], voltage: [Double]) -> (slope: Double, yint: Double, rCorrelation: Double, rSquared: Double) {
        let N = Double(concentration.count)
        let compoundXY = zip(concentration, voltage)
        let XY = compoundXY.map({$0 * $1})
        let XX = concentration.map({$0 * $0})
        let YY = voltage.map({$0 * $0})
        let sumX = concentration.reduce(0, {$0 + $1})
        let sumY = voltage.reduce(0, {$0 + $1})
        let sumXY = XY.reduce(0, {$0 + $1})
        let sumXX = XX.reduce(0, {$0 + $1})
        let sumYY = YY.reduce(0, {$0 + $1})
        let slope = (N*sumXY - sumX*sumY) / (N*sumXX - sumX*sumX)
        let yint = (sumY - slope*sumX) / N
        let rNumerator = (N*sumXY) - (sumX*sumY)
        let rDenominatorFirst = (N*sumXX) - (sumX*sumX)
        let rDenominatorSecond = (N*sumYY) - (sumY*sumY)
        let rCorrelation = rNumerator / sqrt(rDenominatorFirst * rDenominatorSecond)
        let rSquared = rCorrelation * rCorrelation
        return (slope, yint, rCorrelation, rSquared)
    }
    
}