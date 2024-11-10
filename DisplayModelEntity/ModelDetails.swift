//
//  ModelDetails.swift
//  DisplayModelEntity
//
//  Created by funbear GmbH on 23.10.2024.
//

import SwiftUI

struct ModelDetails: View {
    let filename: String
    let height: Float
    let diameter: Float
    let onResetCamera: () -> Void
    let onApplyPreset: (CameraState) -> Void
    let onSaveCurrentState: () -> CameraState
    @Binding var currentModelURL: URL?
    
    @AppStorage("saveCameraPosition") private var saveCameraPosition = false
    @AppStorage("photoSettings") private var photoSettingsData: Data = try! JSONEncoder().encode(PhotoSettings.defaultSettings)
    @AppStorage("lightingSettings") private var lightingSettingsData: Data = try! JSONEncoder().encode(LightingSettings.defaultSettings)
    @StateObject private var cameraManager = CameraStateManager.shared
    @State private var showingNewPresetSheet = false
    @State private var newPresetName = ""
    @State private var currentResolution: PhotoSettings.Resolution
    @State private var currentFormat: PhotoSettings.ImageFormat
    @State private var currentLightingType: LightingSettings.LightingType
    @State private var currentHDR: Bool
    
    @Environment(\.colorScheme) var colorScheme
    
    init(
        filename: String,
        height: Float,
        diameter: Float,
        onResetCamera: @escaping () -> Void,
        onApplyPreset: @escaping (CameraState) -> Void,
        onSaveCurrentState: @escaping () -> CameraState,
        currentModelURL: Binding<URL?>
    ) {
        self.filename = filename
        self.height = height
        self.diameter = diameter
        self.onResetCamera = onResetCamera
        self.onApplyPreset = onApplyPreset
        self.onSaveCurrentState = onSaveCurrentState
        self._currentModelURL = currentModelURL
        
        // Initialize photo settings
        let photoSettings = try? JSONDecoder().decode(PhotoSettings.self, from: UserDefaults.standard.data(forKey: "photoSettings") ?? Data())
        _currentResolution = State(initialValue: photoSettings?.resolution ?? .res1024)
        _currentFormat = State(initialValue: photoSettings?.format ?? .png)
        _currentHDR = State(initialValue: photoSettings?.useHDR ?? false)
        
        // Initialize lighting settings with proper optional handling
        let lightingData = UserDefaults.standard.data(forKey: "lightingSettings")
        let decodedSettings = lightingData.flatMap { try? JSONDecoder().decode(LightingSettings.self, from: $0) }
        _currentLightingType = State(initialValue: decodedSettings?.type ?? LightingSettings.defaultSettings.type)
    }
    
    var photoSettings: PhotoSettings {
        get {
            try! JSONDecoder().decode(PhotoSettings.self, from: photoSettingsData)
        }
        set {
            photoSettingsData = try! JSONEncoder().encode(newValue)
        }
    }
    
    var lightingSettings: LightingSettings {
        get {
            try! JSONDecoder().decode(LightingSettings.self, from: lightingSettingsData)
        }
        set {
            lightingSettingsData = try! JSONEncoder().encode(newValue)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Model Details
            Text("Model Details")
                .font(.headline)
            DetailItem(label: "Filename", value: filename)
            DetailItem(label: "Height", value: String(format: "%.3f m", height))
            DetailItem(label: "Diameter", value: String(format: "%.3f m", diameter))
            
            Spacer()
            
            // Camera Settings
            Divider()
            Text("Camera Settings")
                .font(.headline)
            
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
            Divider()
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
            
            // Lighting Settings
            Divider()
            Text("Lighting Settings")
                .font(.headline)
            
            Picker("Lighting Type", selection: $currentLightingType) {
                ForEach(LightingSettings.LightingType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .onChange(of: currentLightingType) { _, newType in
                // Update lighting settings
                let settings = LightingSettings(type: newType)
                if let encoded = try? JSONEncoder().encode(settings) {
                    UserDefaults.standard.set(encoded, forKey: "lightingSettings")
                }
                
                // Reload model to apply new lighting
                if let currentURL = currentModelURL {
                    DispatchQueue.main.async {
                        self.currentModelURL = nil
                        DispatchQueue.main.async {
                            self.currentModelURL = currentURL
                        }
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
