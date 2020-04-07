//
//  WeightPeripheral.swift
//  LiftingDeviceCapstone
//
//  Created by temp_admin on 3/28/20.
//  Copyright © 2020 temp_admin. All rights reserved.
//

import UIKit
import CoreBluetooth

class WeightPeripheral: NSObject {

    public static let WeightPeripheralServiceUUID = CBUUID.init(string: "961c2d70-6bd8-11ea-bc55-0242ac130003")
    public static let ImuDataCharacteristicUUID   = CBUUID.init(string: "961c2d71-6bd8-11ea-bc55-0242ac130003")

}
