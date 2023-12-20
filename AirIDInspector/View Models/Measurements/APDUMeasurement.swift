// SPDX-License-Identifier: MIT
//
//  APDUMeasurement.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 08/10/2022.
//

import Foundation

typealias MeasurementNanoseconds = UInt64

class APDUMeasurement: ObservableObject, Equatable, Hashable, Identifiable, Codable {
    let operationID: UUID
    
    @Published private(set) var durations: [MeasurementNanoseconds]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(operationID)
    }
    
    var id: UUID {
        operationID
    }
    
    init(operationID: UUID, initialDuration: MeasurementNanoseconds) {
        self.durations = [initialDuration]
        self.operationID = operationID
    }
    
    init(operationID: UUID, durations: [MeasurementNanoseconds] = []) {
        self.operationID = operationID
        self.durations = durations
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(operationID, forKey: .operationID)
        try container.encode(durations, forKey: .durations)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.operationID = try container.decode(UUID.self, forKey: .operationID)
        self.durations = try container.decode([MeasurementNanoseconds].self, forKey: .durations)
    }
    
    static func == (lhs: APDUMeasurement, rhs: APDUMeasurement) -> Bool {
        lhs.operationID == rhs.operationID
    }
    
    func combining(_ measurement: APDUMeasurement) {
        guard measurement.operationID == self.operationID else {
            
            // maybe we could throw an error while attempting to merge measurements of non-identical ids?
            return
        }
        
        self.durations.append(contentsOf: measurement.durations)
    }
    
    func append(duration: MeasurementNanoseconds) {
        self.durations.append(duration)
    }
    
    enum CodingKeys: String, CodingKey {
        case operationID
        case durations
    }
}

extension MeasurementNanoseconds {
    func append(to measurement: APDUMeasurement) {
        measurement.append(duration: self)
    }
}

extension APDUMeasurement: CustomStringConvertible {
    var description: String {
        if durations.isEmpty {
            return "No Measurements yet"
        }
        
        if durations.count == 1 {
            return durations.first!.humanFormatted
        }
        
        let avg = durations.reduce(0, +) / UInt64(durations.count)
        let min = durations.min()!
        let max = durations.max()!
        
        return "MIN: \(min.humanFormatted) AVG: \(avg.humanFormatted) MAX: \(max.humanFormatted)"
    }
}

extension MeasurementNanoseconds {
    static var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.allowsFloats = true
        formatter.alwaysShowsDecimalSeparator = false
        return formatter
    }()
    
    var humanFormatted: String {
        let milliseconds = (self / 1_000_000)
        return Self.numberFormatter.string(from: .init(value: milliseconds))! + "ms"
    }
}
