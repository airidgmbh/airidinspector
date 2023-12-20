// SPDX-License-Identifier: MIT
//
//  APDUSourceSnapshotStore.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 10/10/2022.
//

import Foundation
import AirIDDriver

actor APDUSourceSnapshotStore {
    private(set) static var current: APDUSourceSnapshotStore = .init()
    
    private var contents: [UUID: APDUTestSourceProtocol] = [:]
    
    init() { }
    
    func store(snapshot: APDUTestSourceProtocol, for deviceIdentifier: UUID) {
        self.contents[deviceIdentifier] = snapshot
    }
    
    func snapshot(for deviceIdentifier: UUID) -> APDUTestSourceProtocol? {
        contents[deviceIdentifier]
    }
}
