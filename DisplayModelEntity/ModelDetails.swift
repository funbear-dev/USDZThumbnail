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
    @AppStorage("photoSettings") private var photoSettingsData: Data = try! JSONEncoder().encode(PhotoSettings.defaultSettings)
    @StateObject private var cameraManager = CameraStateManager.shared
    @State private var showingNewPresetSheet = false
    @State private var newPresetName = ""
    @State private var currentResolution: PhotoSettings.Resolution
    @State private var currentFormat: PhotoSettings.ImageFormat
    @State private var currentHDR: Bool
    let onResetCamera: () -> Void
    let onApplyPreset: (CameraState) -> Void
    let onSaveCurrentState: () -> CameraState
    
    @Environment(\.colorScheme) var colorScheme
    
    
    init(filename: String, height: Float, diameter: Float, onResetCamera: @escaping () -> Void, onApplyPreset: @escaping (CameraState) -> Void, onSaveCurrentState: @escaping () -> CameraState) {
        let settings = try? JSONDecoder().decode(PhotoSettings.self, from: UserDefaults.standard.data(forKey: "photoSettings") ?? Data())
        _currentResolution = State(initialValue: settings?.resolution ?? .res1024)
        _currentFormat = State(initialValue: settings?.format ?? .png)
        _currentHDR = State(initialValue: settings?.useHDR ?? false)
        self.filename = filename
        self.height = height
        self.diameter = diameter
        self.onResetCamera = onResetCamera
        self.onApplyPreset = onApplyPreset
        self.onSaveCurrentState = onSaveCurrentState
    }
    
    
    var photoSettings: PhotoSettings {
        get {
            try! JSONDecoder().decode(PhotoSettings.self, from: photoSettingsData)
        }
        set {
            photoSettingsData = try! JSONEncoder().encode(newValue)
        }
    }
    
    
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
                
                // Photo Settings
                Group {
                    Text("Photo Settings")
                        .font(.subheadline)
                        .padding(.top, 8)
                    
                    Picker("Resolution", selection: $currentResolution) {
                        ForEach(PhotoSettings.Resolution.allCases) { resolution in
                            Text(resolution.description).tag(resolution)
                        }
                    }
                    .labelsHidden()
                    .onChange(of: currentResolution) {
                        saveSettings()
                    }
                    
                    Picker("Format", selection: $currentFormat) {
                        ForEach(PhotoSettings.ImageFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .labelsHidden()
                    .onChange(of: currentFormat) {
                        saveSettings()
                    }
                    
                    Toggle("HDR", isOn: $currentHDR)
                        .font(.caption)
                        .onChange(of: currentHDR) {
                            saveSettings()
                        }
                }

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
    
    
    private func saveSettings() {
        let settings = PhotoSettings(
            resolution: currentResolution,
            format: currentFormat,
            useHDR: currentHDR
        )
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: "photoSettings")
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
