// SPDX-License-Identifier: MIT
//
//  DeviceStatus.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 13/09/2022.
//

import Foundation
import SwiftUI
import AirIDDriver

enum DeviceStatus: String, CustomStringConvertible {
    case absent
    case connected
    case initialized
    case present
    
    init(deviceStatus: AIDDeviceStatus) {
        switch deviceStatus {
        case .absent:
            self = .absent
        case .present:
            self = .present
        case .connected:
            self = .connected
        case .initialized:
            self = .initialized
        @unknown default:
            self = .absent
        }
    }
    
    var description: String {
        switch self {
        case .absent: return "Absent"
        case .connected: return "Connected"
        case .initialized: return "Initialized"
        case .present: return "Present"
        }
    }
    
    var isConnected: Bool {
        switch self {
        case .connected, .initialized: return true
        case .absent, .present: return false
        }
    }
    
    var color: Color {
        switch self {
        case .connected: return .orange
        case .absent: return .gray
        case .initialized: return .green
        case .present: return .yellow
        }
    }
}
