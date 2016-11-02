//
//  Patient.swift
//  Sweat
//
//  Created by Brian Cueto on 10/28/16.
//  Copyright © 2016 Brian_INBT. All rights reserved.
//

import Foundation

class Patient {
    
    private var _ID: String = ""
    private var Calibrations = [Calibration]()
    private var Experiments = [Experiment]()
    
    var ID: String {
        get {
            return self._ID
        }
        set {
            _ID = newValue
        }
    }
    
    func addCalibration(newCalibrate : Calibration) {
        self.Calibrations.append(newCalibrate)
    }
    
    func addExperiments(newExperiment : Experiment) {
        self.Experiments.append(newExperiment)
    }


}
