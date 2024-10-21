//
//  ViewModel.swift
//  DisplayModelEntity
//
//  Created by Stefano Rebulla on 21.10.2024.
//

import SwiftUI
import RealityKit


class ViewModel: ObservableObject {
    @Published var modelLoaded = false
    let arView: ARView
    private var entity: Entity?
    
    // Sensitivity factors
    private let panSensitivity: Float = 0.0001
    private let rotateSensitivity: Float = 0.001
    private let zoomSensitivity: Float = 0.00005
    
    init() {
        arView = ARView(frame: .zero)
        arView.environment.background = .color(.clear)
    }
    
    @MainActor
    func loadModel(from url: URL) async {
        print("Attempting to load model from: \(url.path)")
        do {
            let entity = try await ModelEntity(contentsOf: url)
            
            print("Model loaded successfully")
            
            // Remove existing entities
            arView.scene.anchors.removeAll()
            
            // Add the new entity
            let anchor = AnchorEntity(world: .zero)
            anchor.addChild(entity)
            arView.scene.addAnchor(anchor)
            
            // Position the model in front of the camera
            entity.position = [0, 0, -1]
//            entity.scale = [0.8, 0.8, 0.8]  // Adjust scale here
            
            self.entity = entity
            self.modelLoaded = true
            
            print("Model added to scene")
        } catch {
            print("Failed to load model: \(error.localizedDescription)")
        }
    }
    
    func handlePanGesture(translation: CGSize) {
        guard let entity = entity else { return }
        
        if NSEvent.modifierFlags.contains(.option) {
            // Pan (translate) the model
            entity.position += SIMD3<Float>(
                Float(translation.width) * panSensitivity,
                -Float(translation.height) * panSensitivity,
                0
            )
        } else if NSEvent.modifierFlags.contains(.command) {
            // Rotate the model
            entity.orientation *= simd_quatf(
                angle: Float(translation.width) * rotateSensitivity,
                axis: [0, 1, 0]
            )
            entity.orientation *= simd_quatf(
                angle: Float(translation.height) * rotateSensitivity,
                axis: [1, 0, 0]
            )
        }
    }
    
    func handleScrollWheel(with event: NSEvent) {
        guard let entity = entity else { return }
        
        let zoomFactor = 1 + Float(event.deltaY) * zoomSensitivity
        entity.scale *= SIMD3<Float>(zoomFactor, zoomFactor, zoomFactor)
    }
}
