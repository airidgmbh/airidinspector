// SPDX-License-Identifier: MIT
//
//  APDUTestSourceNone.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 08/10/2022.
//

import Foundation

class APDUTestSourceNone: APDUTestSourceProtocol {
    func getAPDUTestOperations(for device: DeviceProtocol) throws -> [APDUBaseOperation] {
        []
    }
}
