// SPDX-License-Identifier: MIT
//
//  APDUTestsViewModel.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 14/09/2022.
//

import Foundation
import Combine
import AirIDDriver

@MainActor
class APDUTestsViewModel: ObservableObject {
    
    @Published var operations: [APDUBaseOperation] = []
    @Published var error: Error?
    @Published var isOperationsRunning: Bool = false
    
    @Published var source: APDUTestSourceProtocol? {
        didSet {
            guard let source = self.source else { return }
            
            do {
                self.operations = try source.getAPDUTestOperations(for: device)
            } catch {
                self.error = error
                return
            }
        }
    }
    
    let device: DeviceProtocol
    let runner: APDUTestsRunner
    
    init(device: DeviceProtocol) {
        self.device = device
        self.runner = .init()
    }
    
    func initializeSnapshotIfNeeded() {
        Task {
            if let snapshot = await APDUSourceSnapshotStore.current.snapshot(for: self.device.id) {
                self.source = snapshot
            }
        }
    }
    
    func saveSnapshotIfNeeded() {
        Task {
            if !operations.isEmpty {
                // create a snapshot from the current operations
                let snapshot = APDUTestSourceSnapshot(operations: operations)
                await APDUSourceSnapshotStore.current.store(snapshot: snapshot, for: device.id)
            }
        }
    }
    
    func start() async throws {
        defer {
            isOperationsRunning = false
        }
        
        await MainActor.run { isOperationsRunning = true }
        
        for operation in operations {
            do {
                try await operation.tryStart()
                await operation.state(to: .success)
            } catch {
                if error is CancellationError {
                    await operation.state(to: .failed(.cancelled))
                } else {
                    await operation.state(to: .failed(.explicit(error.localizedDescription)))
                }
                
                break
            }
        }
        
        
        try await device.shutDown()
    }
    
    func start(count: Int = 1) {
        Task {
            for _ in 0..<count {
                do {
                    try await self.start()
                } catch {
                    self.error = error
                }
            }
        }
    }
    
    func exportTest() throws -> Data {
        // TODO: Export the test, probably saving it to a document and then sharing the same data as JSON.
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        return try encoder.encode(self.operations)
    }
}

actor APDUTestsRunner {
    private var previousTask: Task<(), Error>?

    func add(block: @Sendable @escaping () async throws -> Void) {
        previousTask = Task { [previousTask] in
            let _ = await previousTask?.result
            return try await block()
        }
    }
}
