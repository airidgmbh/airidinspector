// SPDX-License-Identifier: MIT
//
//  APDULegacyBenchTimer.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 08/10/2022.
//

import Foundation

struct APDULegacyBenchTimer: APDUBenchTimerProtocol {
    func measure(_ operation: (() async throws -> Void)) async rethrows -> MeasurementNanoseconds {
        let start = DispatchTime.now()
        try await operation()
        let end = DispatchTime.now()
        
        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
        return nanoTime
    }
}
