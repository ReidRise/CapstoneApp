//
//  SecondViewController.swift
//  LiftingDeviceCapstone
//
//  Created by temp_admin on 3/22/20.
//  Copyright © 2020 temp_admin. All rights reserved.
//

import UIKit
import Charts
import CoreBluetooth

class SecondViewController: UIViewController, CBPeripheralDelegate, CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
    }
    
    @IBOutlet weak var chtBarpath: ScatterChartView!
    
    var vel_x: [Double] = [Double()]
    var vel_y: [Double] = [Double()]
    
    var x_position:[Double] = [0]
    var y_position:[Double] = [0]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    @IBAction func btnBarpath(_ sender: Any) {
        vel_x = imuData.sharedData.velocity_x
        vel_y = imuData.sharedData.velocity_y
        x_position.removeAll()
        x_position.append(0.0)
        y_position.removeAll()
        y_position.append(0.0)
        processDistance()
        updateGraph()
    }
    
    func updateGraph(){
        var lineChartEntry = [ChartDataEntry]()
    
        for i in 0 ..< x_position.count{
            let entry = ChartDataEntry(x: Double(x_position[i]), y: Double(y_position[i]))
            lineChartEntry.append(entry)
        }
        lineChartEntry.sort(by: { $0.x < $1.x })
        let line1 = ScatterChartDataSet(entries: lineChartEntry)
        let data = ScatterChartData()
        data.addDataSet(line1)
        chtBarpath.data = data
        
        chtBarpath.drawGridBackgroundEnabled = true
        chtBarpath.gridBackgroundColor = UIColor.white
        chtBarpath.backgroundColor = UIColor.white
        
        chtBarpath.chartDescription?.text = "Barpath"
        chtBarpath.animate(xAxisDuration: (Double(x_position.count) * 0.01))
    }
    
    func processDistance() {
        var start = 0
        print("Total Data Points: \(vel_x.count)")
        for i in 0 ..< vel_x.count - 1 {
            if (vel_y[i] < 0.0 && vel_y[i + 1] >= 0.0) {
                x_position.append((vel_x[i] * 0.01) + x_position[i])
                y_position.append((vel_y[i] * 0.01) + y_position[i])
            }
            else {
                x_position.append((vel_x[i] * 0.01) + x_position[i])
                y_position.append((vel_y[i] * 0.01) + y_position[i])
            }
        }
        normalizeCurve(start: start, end: x_position.count - 1)
    }
    func normalizeCurve (start: Int, end: Int){
        print("start: \(start)")
        print("end: \(end)")
        
        let tan_vely = y_position[end] / Double(end) // Find the tangent of the diviation
        var deviation = 0.0
        
        for i in start ..< end + 1 {
            deviation = tan_vely * Double(i)
            y_position[i] -= deviation
        }
        
        let tan_velx = x_position[end] / Double(end) // Find the tangent of the diviation
        
        for i in start ..< end + 1 {
            deviation = tan_velx * Double(i)
            x_position[i] -= deviation
        }
    }
}

