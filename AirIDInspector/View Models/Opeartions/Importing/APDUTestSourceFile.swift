// SPDX-License-Identifier: MIT
//
//  APDUTestSourceFile.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 08/10/2022.
//

import Foundation

class APDUTestSourceFile: APDUTestSourceProtocol {
    let fileURL: URL
    
    init(url: URL) {
        self.fileURL = url
    }
    
    func getAPDUTestOperations(for device: DeviceProtocol) throws -> [APDUBaseOperation] {
        let rawString = try String(contentsOf: fileURL)
        return try APDUTestSourceString(string: rawString)
            .getAPDUTestOperations(for: device)
    }
}
