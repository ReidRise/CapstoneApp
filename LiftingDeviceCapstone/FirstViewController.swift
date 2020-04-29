//
//  FirstViewController.swift
//  LiftingDeviceCapstone
//
//  Created by Reid Rise on 3/22/20.
//  Copyright © 2020 Reid Rise. All rights reserved.
//

import UIKit
import Charts
import CoreBluetooth

class FirstViewController: UIViewController, CBPeripheralDelegate, CBCentralManagerDelegate, UITextFieldDelegate  {
    
    private var centralManager: CBCentralManager!                        // Phone part of bluetooth
    private var peripheral: CBPeripheral!                                // ESP32 part of bluetooth
    @IBOutlet weak var txtBluetoothConnection: UILabel!                  // Shows connection to bluetooth device
    
    @IBOutlet weak var chtVelocity: LineChartView!                       // Chart that plots velocity
    
    @IBOutlet weak var txtWeight: UITextField!                           // Text element for adding weight data (works to add in test data currently)
    @IBOutlet weak var txtAvgVel: UILabel!                               // Text element for displaying average velocity
    @IBOutlet weak var txtTotPower: UILabel!                             // Text element for displaying total power in ft/lbs
    
    var velocity_x:[Double] = [0]                                        // Holds velocity data
    var velocity_y:[Double] = [0]
    var acceleration_x:[Double] = [0.331, 0.231, 0.552, 0.023, 0.223]    // Holds acceleration data
    var acceleration_y:[Double] = [0.331, 0.231, 0.552, 0.023, 0.223]
    
    var unprocessed_data:[UInt8] = []
    var unprocessed_x:Int16 = 0
    var unprocessed_y:Int16 = 0
    
    var weight:Double = 1.0                                              // Weight of bar in lbs
    var total_time:Double = 1.00                                         // Total time elapsed in seconds
    
    var moreData = false                                                 // Determains if program should wait for more data
    
    override func viewDidLoad() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
        self.txtWeight.delegate = self
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    
    // Hide keyboard
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func btnGenerate(_ sender: Any) {
        // Aqiure and store data
        let input = Double(txtWeight.text!) // Gets number from textbox
        // velocity_y.append(input!) // Adds Velocity to dataset *test*
        weight = input! // Set weight to input
        
        // Calculate avg velocity and populate acceleration array for power calculation
        var velocity_max = 0.0
        var distance = 0.0
        for i in 0 ..< velocity_y.count {
            if velocity_y[i] > 0.0 {
                if velocity_y[i] > velocity_max{
                    velocity_max = velocity_y[i]
                }
                distance += velocity_y[i] * 0.01
            }
        }
        
        txtAvgVel.text = String(velocity_max) // display this velocity
        
        // Calculate total time elapsed from inputs.
        total_time = Double(velocity_y.count) * 0.01                   // Multiplies the number of samples by the sample rate to determine total time
        
        // Calculate and display total power
        let total_power = ((weight * 32.2) * distance) / total_time    // Calculate sum of work and divide it by the total time
        txtTotPower.text = String(total_power)
        
        updateGraph()
    }
    
    func updateGraph(){
        var lineChartEntry = [ChartDataEntry]()
        
        for i in 0 ..< velocity_y.count{ // For all data in velocity array
            let time = Double(i) * 0.01
            let entry = ChartDataEntry(x: time, y: velocity_y[i]) // Create a point on the chart
            lineChartEntry.append(entry)
        }
        let line1 = LineChartDataSet(entries: lineChartEntry, label: "Velocity") // Label the data
        let data = LineChartData()                                               // Create data
        
        data.addDataSet(line1) // Add the data to the chart
        
        chtVelocity.data = data
        chtVelocity.drawGridBackgroundEnabled = true
        chtVelocity.gridBackgroundColor = UIColor.white
        chtVelocity.backgroundColor = UIColor.white
        chtVelocity.chartDescription?.text = "Velocity vs Time" // Add a label for the entire graph
    }
    
    // Powered up, Scanning Starts
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central state update")
        if central.state != .poweredOn {
            print("Central is not powered on")
            txtBluetoothConnection.text = "Not Connected"
        } else {
            print("Central scanning for", WeightPeripheral.WeightPeripheralServiceUUID);
            centralManager.scanForPeripherals(withServices:nil,
                                              options: nil)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("\nName   : \(peripheral.name ?? "(No name)")")
        print("RSSI   : \(RSSI)")
        for ad in advertisementData {
            print("AD Data: \(ad)")
        }
        if peripheral.name == "ESP_GATTS_DEMO" {
            // We've found it so stop scan
            self.centralManager.stopScan()

            // Copy the peripheral instance
            self.peripheral = peripheral
            self.peripheral.delegate = self

            // Connect!
            self.centralManager.connect(self.peripheral, options: nil)
        }
    }
    
    // The handler if we do connect succesfully
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == self.peripheral {
            print("Connected to your WLDevice")
            txtBluetoothConnection.text = "Connected"
            peripheral.discoverServices([WeightPeripheral.WeightPeripheralServiceUUID])
        }
    }
    
    // The handler if we do connect succesfully
    func centralManager(_ central: CBCentralManager, didDisconnect peripheral: CBPeripheral) {
        if peripheral == self.peripheral {
            print("Disconnected From Device")
            txtBluetoothConnection.text = "Not Connected"
            peripheral.discoverServices([WeightPeripheral.WeightPeripheralServiceUUID])
        }
    }
    
    // Handles discovery event
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == WeightPeripheral.WeightPeripheralServiceUUID {
                    print("Capstone service found")
                    //Now kick off discovery of characteristics
                    peripheral.discoverCharacteristics(nil, for: service)
                    return
                }
            }
        }
    }
    
    // Handling discovery of characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == WeightPeripheral.ImuDataCharacteristicUUID {
                    print("IMU Found!!!")
                    peripheral.setNotifyValue(true, for: characteristic) // Subscribe to the value
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let e = error {
            print("ERROR didUpdateValue \(e)")
            return
        }
        guard let data = characteristic.value else { return }
        var byteArray = [UInt8](data)
        
        var ack:UInt8 = 0x55
        let writeAck = Data(bytes: &ack, count: MemoryLayout.size(ofValue: ack))
        
        if byteArray[0] == 0x4E {
            notificationSent(peripheral: peripheral, characteristic: characteristic, byteArray: byteArray)
            if byteArray[1] != 0x50 {
                peripheral.writeValue(writeAck, for: characteristic, type: CBCharacteristicWriteType.withResponse)         // Send data read acknowlodge
            }
        } else if byteArray[0] == 0x44 {
            byteArray.remove(at: 0)
            byteArray.remove(at: (byteArray.count - 1))
            // print("First byte \(byteArray[0])")
            unprocessed_data.append(contentsOf: byteArray)
            print("Unprocessed Total: \(unprocessed_data.count)")
            // print(byteArray)
        } else {
            print("Bad send no header")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    func notificationSent(peripheral: CBPeripheral, characteristic: CBCharacteristic, byteArray: [UInt8] ){
        switch byteArray[1] {                               // Check notification type
        case 0x43:                                          // Clear old data for new data
            print("New Data Being Sent Clearing Old Data")
            velocity_x.removeAll()
            velocity_y.removeAll()
            velocity_x.append(0.0)
            velocity_y.append(0.0)
            acceleration_x.removeAll()
            acceleration_y.removeAll()
            unprocessed_data.removeAll()
            break
        case 0x4E:                                          // Normal data transmisson
            print("Reading New Value for IMU Data")
            peripheral.readValue(for: characteristic)       // Read new data
            break
        case 0x50:                                          // Process data end transmission
            print("Data Transfer Complete Total Sent: \(unprocessed_data.count)")
            processNewData()
            updateGraph()                                   // Generates new graph based on new data
            break
        default:
            print("Abnormal status no action")
        }
    }
    
    func processNewData(){
        // print(unprocessed_data)
        while (unprocessed_data.count % 4) != 0 {                                  
            unprocessed_data.remove(at: unprocessed_data.count - 1)
            print("OOF VERY BAD PLEASE DONT PRINT ME")
        }
        
        var i = 0 // unprocessed data index
        var j = 0 // Velocity index
        
        while i < unprocessed_data.count {
            
            // Process X coord data
            unprocessed_x = Int16(unprocessed_data[i + 1]) << 8
            unprocessed_x |= Int16(unprocessed_data[i])
            print("Unprocessed x: \(unprocessed_x)")
            acceleration_x.append(Double(unprocessed_x) * 0.01)                   // Convert to m/s^2
            velocity_x.append(((acceleration_x[j] * 0.01) + velocity_x[j]))
            
            // Process Y coord data
            unprocessed_y = Int16(unprocessed_data[i + 3]) << 8
            unprocessed_y |= Int16(unprocessed_data[i + 2])
            print("Unprocessed y: \(unprocessed_y)")
            acceleration_y.append(Double(unprocessed_y) * 0.01)
            velocity_y.append(((acceleration_y[j] * 0.01) + velocity_y[j]))
            
            j += 1
            i += 4
        }
        
        for i in 0 ..< velocity_x.count {                                          // convert to ft/s
            velocity_x[i] *=  3.28084
            velocity_y[i] *=  3.28084
        }
        
        // Normalize Velocity
        normalizeCurve()
        
        imuData.sharedData.velocity_x = velocity_x                                 // Share data with second view
        imuData.sharedData.velocity_y = velocity_y
    }
    
    func normalizeCurve (){
        let tan_vely = velocity_y[velocity_y.count - 1] / Double(velocity_y.count) // Find the tangent of the diviation
        var deviation = 0.0
        
        for i in 1 ..< velocity_y.count {
            deviation = tan_vely * Double(i)
            velocity_y[i] -= deviation
        }
        
        let tan_velx = velocity_x[velocity_x.count - 1] / Double(velocity_x.count) // Find the tangent of the diviation
        
        for i in 1 ..< velocity_x.count {
            deviation = tan_velx * Double(i)
            velocity_x[i] -= deviation
        }
    }
    
}

