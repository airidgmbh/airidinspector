// SPDX-License-Identifier: MIT
//
//  CardStatus.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 20/09/2022.
//

import Foundation
import AirIDDriver

typealias CardStatus = AIDCardStatus

extension CardStatus {
    var name: String {
        switch self {
        case .absent:
            return "Absent"
        case .inPosition:
            return "In Position"
        case .negotiable:
            return "Negotiable"
        case .powered:
            return "Powered"
        case .present:
            return "Present"
        case .specific:
            return "Specific"
        case .unknown:
            return "Uknown"
        @unknown default:
            return "Unkonwn"
        }
    }
}
