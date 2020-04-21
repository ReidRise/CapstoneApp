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
        //chtBarpath.setVisibleXRangeMaximum(0.5)
        //chtBarpath.setVisibleXRangeMinimum(-0.5)
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
        // chtBarpath.animate(xAxisDuration: (Double(x_position.count) * 0.01))
    }
    
    func processDistance() {
        var start = 0
        var x_temp: [Double] = [0.0]
        var y_temp: [Double] = [0.0]
        print("Total Data Points: \(vel_x.count)")
        for i in 0 ..< vel_x.count - 1 {
            if (vel_y[i] < 0.0 && vel_y[i + 1] >= 0.0) {
                x_temp.append((vel_x[i] * 0.01) + x_temp[i - start])
                y_temp.append((vel_y[i] * 0.01) + y_temp[i - start])
                normalizeCurve(x_seg: x_temp, y_seg: y_temp)
                start = i + 1
                x_temp.removeAll()
                y_temp.removeAll()
                x_temp.append(0.0)
                y_temp.append(0.0)
            }
            else {
                print("i = \(i) : start = \(start) : index = \(i - start) : count = \(x_temp.count)")
                
                x_temp.append((vel_x[i] * 0.01) + x_temp[i - start])
                y_temp.append((vel_y[i] * 0.01) + y_temp[i - start])
            }
        }
        normalizeCurve(x_seg: x_temp, y_seg: y_temp)
    }
    
    func normalizeCurve (x_seg: [Double], y_seg: [Double]){
        var x_temp: [Double] = x_seg
        var y_temp: [Double] = y_seg
        
        let tan_velx = x_seg[x_seg.count - 1] / Double(x_seg.count) // Find the tangent of the diviation
        let tan_vely = y_seg[y_seg.count - 1] / Double(y_seg.count) // Find the tangent of the diviation
        var deviation = 0.0
        
        for i in 0 ..< x_seg.count {
            deviation = tan_vely * Double(i)
            y_temp[i] -= deviation
            deviation = tan_velx * Double(i)
            x_temp[i] -= deviation
        }
        x_position.append(contentsOf: x_temp)
        y_position.append(contentsOf: y_temp)
    }
}

