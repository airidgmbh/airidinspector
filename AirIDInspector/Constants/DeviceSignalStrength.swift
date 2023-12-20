// SPDX-License-Identifier: MIT
//
//  DeviceSignalStrength.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 13/09/2022.
//

import Foundation
import SwiftUI

enum DeviceSignalStrength: Int {
    case rare
    case mediumRare
    case medium
    case mediumWell
    case wellDone
    
    init(strength: Double) {
        if strength < 0 {
            self = .rare
        } else if strength < 0.25 {
            self = .mediumRare
        } else if strength < 0.5 {
            self = .medium
        } else if strength < 0.75 {
            self = .mediumWell
        } else {
            self = .wellDone
        }
    }
    
    var color: Color {
        switch self {
        case .rare:
            return .red
        case .mediumRare:
            return .orange.opacity(0.4)
        case .medium:
            return .orange.opacity(0.55)
        case .mediumWell:
            return .green.opacity(0.7)
        case .wellDone:
            return .green.opacity(1)
        }
    }
    
    var name: String {
        "Strength: \(rawValue)"
    }
}
