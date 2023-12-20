// SPDX-License-Identifier: MIT
//
//  LoadingButton.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 23/09/2022.
//

import SwiftUI

struct LoadingButton<Content: View>: View{
    @Binding var isLoading: Bool

    var style: LoadingButtonStyle
    let content: Content
    var action: () -> () = {}
    
    init(action: @escaping () -> Void, isLoading: Binding<Bool>, style: LoadingButtonStyle? = nil, @ViewBuilder builder: () -> Content) {
        self._isLoading = isLoading
        self.style = style ?? LoadingButtonStyle()
        content = builder()
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            if !isLoading {
                action()
            }
            isLoading = true
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: isLoading ? style.height/2 : style.cornerRadius)
                    .fill(isLoading ? style.loadingBackgroundColor : style.backgroundColor)
                    .frame(width: isLoading ? style.height : style.width, height: style.height)

                if isLoading {
                    CircleLoadingBar(style: style)
                }
                else {
                    VStack { content }
                }
            }
        }
        .frame(width: style.width, height: style.height)
        .disabled(isLoading)
        .animation(.easeInOut, value: isLoading)
    }
}

struct CircleLoadingBar: View {
    @State private var isLoading = false
    @State var style: LoadingButtonStyle
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(style.strokeColor, style: StrokeStyle(lineWidth: style.strokeWidth, lineCap: .round, lineJoin: .round))
            .frame(width: style.height - 20, height: style.height - 20)
            .rotationEffect(Angle(degrees: isLoading ? 360 : 0))
            .animation(Animation.default.repeatForever(autoreverses: false), value: isLoading)
            .onAppear() {
                self.isLoading = true
            }
    }
}

public struct LoadingButtonStyle {
    public init(width: CGFloat? = nil,
                height: CGFloat? = nil,
                cornerRadius: CGFloat? = nil,
                backgroundColor: Color? = nil,
                loadingColor: Color? = nil,
                strokeWidth: CGFloat? = nil,
                strokeColor: Color? = nil) {
        self.width = width ?? 312
        self.height = height ?? 54
        self.cornerRadius = cornerRadius ?? 0
        self.backgroundColor = backgroundColor ?? Color.blue
        self.loadingBackgroundColor = loadingColor ?? self.backgroundColor.opacity(0.6)
        self.strokeWidth = strokeWidth ?? 5
        self.strokeColor = strokeColor ?? Color.gray.opacity(0.6)
    }
    
    /// Width of button
    public var width: CGFloat = 312
    /// Height of button
    public var height: CGFloat = 54
    /// Corner radius of button
    public var cornerRadius: CGFloat = 0
    /// Background color of button
    public var backgroundColor: Color = .blue
    /// Background color of button when loading. 50% opacity of background color gonna be set if blank.
    public var loadingBackgroundColor: Color = Color.blue.opacity(0.5)
    /// Width of circle loading bar stroke
    public var strokeWidth: CGFloat = 5
    /// Color of circle loading bar stroke
    public var strokeColor: Color = Color.gray.opacity(0.6)
}
