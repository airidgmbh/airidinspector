// SPDX-License-Identifier: MIT
//
//  APDUClockBenchTimer.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 08/10/2022.
//

import Foundation

@available(iOS 16.0, *)
struct APDUClockBenchTimer: APDUBenchTimerProtocol {
    let clock = ContinuousClock()
    
    func measure(_ operation: (() async throws -> Void)) async rethrows -> MeasurementNanoseconds {
        
        let duration = try await clock.measure(operation)
        let seconds = duration.components.seconds
        let attoseconds = duration.components.attoseconds
        
        let attoToNano = UInt64(pow(Double(10), Double(9)))
        let secToNano = UInt64(pow(Double(10), Double(9)))
                               
        return UInt64(seconds) * secToNano + UInt64(attoseconds) / attoToNano
    }
}
