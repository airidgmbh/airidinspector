// SPDX-License-Identifier: MIT
//
//  APDUTestSourceProtocol.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 08/10/2022.
//

import Foundation

protocol APDUTestSourceProtocol {
    func getAPDUTestOperations(for device: DeviceProtocol) throws -> [APDUBaseOperation]
}
