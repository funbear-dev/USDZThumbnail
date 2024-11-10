//
//  CameraStateManager.swift
//  USDZThumbnail
//
//  Created by funbear GmbH on 24.10.2024.
//

import AppKit


class CameraStateManager: ObservableObject {
    static let shared = CameraStateManager()
    
    private let userDefaults = UserDefaults.standard
    private let presetsKey = "cameraPresets"
    private let lastStateKey = "lastCameraState"
    
    @Published private(set) var presets: [CameraPreset] = []
    
    init() {
        loadPresets()
    }
    
    private func loadPresets() {
        guard let data = userDefaults.data(forKey: presetsKey) else { return }
        do {
            presets = try JSONDecoder().decode([CameraPreset].self, from: data)
        } catch {
            print("Error loading presets: \(error)")
        }
    }
    
    private func savePresets() {
        do {
            let data = try JSONEncoder().encode(presets)
            userDefaults.set(data, forKey: presetsKey)
        } catch {
            print("Error saving presets: \(error)")
        }
    }
    
    // Add methods for managing the last used state
    func saveState(_ state: CameraState) {
        do {
            let data = try JSONEncoder().encode(state)
            userDefaults.set(data, forKey: lastStateKey)
        } catch {
            print("Error saving last camera state: \(error)")
        }
    }
    
    func loadState() -> CameraState? {
        guard let data = userDefaults.data(forKey: lastStateKey) else { return nil }
        do {
            return try JSONDecoder().decode(CameraState.self, from: data)
        } catch {
            print("Error loading last camera state: \(error)")
            return nil
        }
    }
    
    // Preset management
    func addPreset(name: String, state: CameraState) {
        let preset = CameraPreset(name: name, state: state)
        presets.append(preset)
        savePresets()
    }
    
    func removePreset(withId id: UUID) {
        presets.removeAll { $0.id == id }
        savePresets()
    }
}
