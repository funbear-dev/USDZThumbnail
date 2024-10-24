//
//  CameraPreset.swift
//  DisplayModelEntity
//
//  Created by Stefano Rebulla on 24.10.2024.
//

import Foundation

struct CameraPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var state: CameraState
    
    init(name: String, state: CameraState) {
        self.id = UUID()
        self.name = name
        self.state = state
    }
}
