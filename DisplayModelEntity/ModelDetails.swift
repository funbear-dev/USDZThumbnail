//
//  ModelDetails.swift
//  DisplayModelEntity
//
//  Created by Stefano Rebulla on 23.10.2024.
//

import SwiftUI

struct ModelDetails: View {
    let filename: String
    let height: Float
    let diameter: Float
    @AppStorage("saveCameraPosition") private var saveCameraPosition = false
    @StateObject private var cameraManager = CameraStateManager.shared
    @State private var showingNewPresetSheet = false
    @State private var newPresetName = ""
    let onResetCamera: () -> Void
    let onApplyPreset: (CameraState) -> Void
    let onSaveCurrentState: () -> CameraState
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Model Details section
            Group {
                Text("Model Details")
                    .font(.headline)
                DetailItem(label: "Filename", value: filename)
                DetailItem(label: "Height", value: String(format: "%.3f m", height))
                DetailItem(label: "Diameter", value: String(format: "%.3f m", diameter))
            }
            
            Spacer()
            
            // Camera Settings section
            Group {
                Divider()
                Text("Camera Settings")
                    .font(.headline)
                
                // Camera presets
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(cameraManager.presets) { preset in
                        HStack {
                            Button(preset.name) {
                                onApplyPreset(preset.state)
                            }
                            .buttonStyle(.link)
                            
                            Spacer()
                            
                            Button(role: .destructive) {
                                cameraManager.removePreset(withId: preset.id)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Button("Save Current View...") {
                        showingNewPresetSheet = true
                    }
                    .font(.caption)
                }
                
                Button("Reset Camera") {
                    onResetCamera()
                }
                .font(.caption)
            }
        }
        .padding()
        .frame(maxHeight: .infinity)
        .background(colorScheme == .dark ? Color(nsColor: .darkGray) : Color(nsColor: .lightGray))
        .sheet(isPresented: $showingNewPresetSheet) {
            SavePresetView(
                isPresented: $showingNewPresetSheet,
                onSave: { name in
                    let state = onSaveCurrentState()
                    cameraManager.addPreset(name: name, state: state)
                }
            )
        }
    }
}

struct DetailItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

//#Preview {
//    ModelDetails(filename: "test.usdz", height: 1.23, diameter: 0.13)
//}
