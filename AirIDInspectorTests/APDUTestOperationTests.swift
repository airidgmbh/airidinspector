//
//  APDUTestOperationTests.swift
//  AirIDDemoTests
//
//  Created by Hussein AlRyalat on 05/11/2022.
//

import XCTest
@testable import AirIDDemo

final class APDUTestOperationTests: XCTestCase {
    
    let APDUTest = """
    00A404000BA0000003974349445F0100
    6...
    00CA7F6800
    6a88
    00A4040009A00000030800001000
    """
    
    var device: MockedDevice!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.device = MockedDevice(id: UUID(),
                                   signalStrength: .medium,
                                   status: .initialized)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testSerializationOfAPDUFile() {
        
    }
    
    func testRegexAPDU() async throws {
        var lines = self.APDUTest.components(separatedBy: .newlines)
        
        let data = lines.removeFirst().hexadecimal!
        let response = lines.removeFirst()
        
        let apduOperation = APDUTestOperation(device: device,
                                              data: data,
                                              expectedResponse: response)
        device.setNextExpectedResponse("6000".hexadecimal!)
        try await apduOperation.tryStart()
        
    }
}
