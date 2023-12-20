// SPDX-License-Identifier: MIT
//
//  DeviceViewModel.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 13/09/2022.
//

import Foundation
import SwiftUI
import Combine
import AirIDDriver

@MainActor
class DeviceViewModel: ObservableObject, Identifiable {
    
    let device: DeviceProtocol
    let id: UUID
    
    @Published var name: String
    @Published var signalStrength: DeviceSignalStrength
    @Published var status: DeviceStatus
    @Published var cardStatus: CardStatus
    @Published var error: Error?
    
    var cancellables: Set<AnyCancellable> = []
    
    let testsViewModel: APDUTestsViewModel
    
    init(device: DeviceProtocol) {
        self.device = device
        self.id = device.id
        self.name = ""
        self.signalStrength = .rare
        self.status = .absent
        self.cardStatus = .absent
        self.testsViewModel = .init(device: device)
        
        device.name.receive(on: DispatchQueue.main).assign(to: \.name, on: self).store(in: &cancellables)
        device.status.receive(on: DispatchQueue.main).assign(to: \.status, on: self).store(in: &cancellables)
        device.cardStatus.receive(on: DispatchQueue.main).assign(to: \.cardStatus, on: self).store(in: &cancellables)
        device.signalStrength.receive(on: DispatchQueue.main).assign(to: \.signalStrength, on: self).store(in: &cancellables)
    }
    
    func connect() {
        Task {
            do {
                try await device.connect()
            } catch {
                self.error = error
            }
        }
    }
    
    func disconnect() {
        Task {
            do {
                try await device.disconnect()
            } catch {
                self.error = error
            }
        }
    }
}
