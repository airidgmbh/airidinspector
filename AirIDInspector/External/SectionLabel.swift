// SPDX-License-Identifier: MIT
//
//  SectionLabel.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 16/09/2022.
//

import Foundation
import SwiftUI

struct SectionLabel: View {
    let text: String
    
    var body: some View {
        
        HStack {
            Text(text)
                .multilineTextAlignment(.leading)
                .font(.headline)
            Spacer()
        }.padding()
    }
}
