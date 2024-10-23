//
//  CameraStateManager.swift
//  DisplayModelEntity
//
//  Created by Stefano Rebulla on 24.10.2024.
//

import AppKit


class CameraStateManager {
    static let shared = CameraStateManager()
    
    private let userDefaults = UserDefaults.standard
    private let cameraStateKey = "savedCameraState"
    
    func saveState(_ state: CameraState) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(state)
            userDefaults.set(data, forKey: cameraStateKey)
        } catch {
            print("Error saving camera state: \(error)")
        }
    }
    
    func loadState() -> CameraState? {
        guard let data = userDefaults.data(forKey: cameraStateKey) else { return nil }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(CameraState.self, from: data)
        } catch {
            print("Error loading camera state: \(error)")
            return nil
        }
    }
}
