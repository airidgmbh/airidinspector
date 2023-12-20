// SPDX-License-Identifier: MIT
//
//  APDUBenchTimerProtocol.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 08/10/2022.
//

import Foundation

protocol APDUBenchTimerProtocol {
    
    /**
     Measures a specific time for the operation to run, the operation should preserve the measurement.
     */
    func measure(_ operation: (() async throws -> Void)) async rethrows -> MeasurementNanoseconds
}
