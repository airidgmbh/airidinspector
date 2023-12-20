// SPDX-License-Identifier: MIT
//
//  FilePicker.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 16/09/2022.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct FilePicker<LabelView: View>: View {
    
    typealias PickedURLsCompletionHandler = (_ urls: [URL]) -> Void
    typealias LabelViewContent = () -> LabelView
    
    @State private var isPresented: Bool = false
    
    let types: [UTType]
    let allowMultiple: Bool
    let pickedCompletionHandler: PickedURLsCompletionHandler
    let labelViewContent: LabelViewContent
    
    init(types: [UTType], allowMultiple: Bool = false, onPicked completionHandler: @escaping PickedURLsCompletionHandler, @ViewBuilder label labelViewContent: @escaping LabelViewContent) {
        self.types = types
        self.allowMultiple = allowMultiple
        self.pickedCompletionHandler = completionHandler
        self.labelViewContent = labelViewContent
    }
    
    init(types: [UTType], allowMultiple: Bool = false, title: String, onPicked completionHandler: @escaping PickedURLsCompletionHandler) where LabelView == Text {
        self.init(types: types, allowMultiple: allowMultiple, onPicked: completionHandler) { Text(title) }
    }
    
    var body: some View {
        Button(
            action: {
                if !isPresented { isPresented = true }
            },
            label: {
                labelViewContent()
            }
        )
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(isPresented)
        .sheet(isPresented: $isPresented) {
            FilePickerUIRepresentable(types: types, allowMultiple: allowMultiple, onPicked: pickedCompletionHandler)
        }
    }
}

struct FilePickerUIRepresentable: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIDocumentPickerViewController
    typealias PickedURLsCompletionHandler = (_ urls: [URL]) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    let types: [UTType]
    let allowMultiple: Bool
    let pickedCompletionHandler: PickedURLsCompletionHandler
    
    init(types: [UTType], allowMultiple: Bool, onPicked completionHandler: @escaping PickedURLsCompletionHandler) {
        self.types = types
        self.allowMultiple = allowMultiple
        self.pickedCompletionHandler = completionHandler
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = allowMultiple
        return picker
    }
    
    func updateUIViewController(_ controller: UIDocumentPickerViewController, context: Context) {}
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: FilePickerUIRepresentable
        
        init(parent: FilePickerUIRepresentable) {
            self.parent = parent
        }
        
        public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.pickedCompletionHandler(urls)
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
