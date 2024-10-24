//
//  SavePresetView.swift
//  DisplayModelEntity
//
//  Created by Stefano Rebulla on 24.10.2024.
//

import SwiftUI


struct SavePresetView: View {
    @Binding var isPresented: Bool
    @State private var presetName = ""
    let onSave: (String) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Save Camera Preset")
                .font(.headline)
            
            TextField("Preset Name", text: $presetName)
                .textFieldStyle(.roundedBorder)
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                
                Button("Save") {
                    onSave(presetName)
                    isPresented = false
                }
                .disabled(presetName.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
