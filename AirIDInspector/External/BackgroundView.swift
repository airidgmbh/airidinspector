// SPDX-License-Identifier: MIT
//
//  BackgroundView.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 16/09/2022.
//

import SwiftUI

struct BackgroundView<ContentView: View>: View {
    let content: (() -> ContentView)
    
    init(@ViewBuilder contentView: @escaping (() -> ContentView)) {
        self.content = contentView
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .foregroundColor(.secondaryBackground)
            content().padding()
        }.padding(.horizontal)
    }
}

struct BackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        BackgroundView() {
            Label("Hello World", systemImage: "xmark").padding()
        }
    }
}
