// SPDX-License-Identifier: MIT
//
//  APDUTestSourceMocked.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 08/10/2022.
//

import Foundation

class APDUTestSourceMocked: APDUTestSourceString {
    private static var rawString = """
    00A404000BA0000003974349445F0100
    6a82
    00CA7F6800
    6a88
    00A4040009A00000030800001000
    6a82
    00A4040009A00000039742544659
    9000
    00A4000C023FFF
    9000
    00CBA000045C02DF1F00
    9000
    """
    
    init() {
        super.init(string: Self.rawString)
    }
}
