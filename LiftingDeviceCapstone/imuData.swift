//
//  imuData.swift
//  LiftingDeviceCapstone
//
//  Created by temp_admin on 4/9/20.
//  Copyright © 2020 temp_admin. All rights reserved.
//

import Foundation
class imuData {
    static let sharedData = imuData()
    var velocity_x:[Double] = [0]
    var velocity_y:[Double] = [0]
}
