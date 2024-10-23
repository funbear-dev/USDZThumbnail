//
//  Coordinator.swift
//  DisplayModelEntity
//
//  Created by Stefano Rebulla on 23.10.2024.
//

import Foundation
import RealityKit


class Coordinator {
    
    @Published var modelLoaded = false
    
    private var isCurrentlyLoading = false // Add this to prevent concurrent loads
    var parent: RealityKitView
    var currentURL: URL?
    private var entity: ModelEntity?
    private var anchor: AnchorEntity?

    init(_ parent: RealityKitView) {
        self.parent = parent
        self.currentURL = parent.usdzURL
        self.modelLoaded = false
        self.isCurrentlyLoading = false
    }
    
    
    @MainActor
    func loadModel(into arView: ARView, context: URL) async {
        // Prevent concurrent loading
        guard !isCurrentlyLoading else {
            print("Model loading already in progress, skipping...")
            return
        }
        
        isCurrentlyLoading = true
        print("\n=== Model Loading Started ===")
        print("Loading model from URL: \(context.path)")
        
        do {
            print("Attempting to load model...")
            let entity = try await ModelEntity.init(contentsOf: context)
            print("Model entity created successfully")
            
            // Clean up existing content
            await MainActor.run {
                print("Cleaning up existing anchors...")
                arView.scene.anchors.forEach { anchor in
                    if anchor.name == "ModelAnchor" {
                        print("Removing existing ModelAnchor")
                        arView.scene.removeAnchor(anchor)
                    }
                }
            }
            
            let anchor = AnchorEntity(world: [0, 1, -3])
            anchor.name = "ModelAnchor"
            print("Created new anchor at position [0, 1, -3]")
            
            if let bounds = entity.model?.mesh.bounds {
                let maxDimension = max(bounds.extents.x, bounds.extents.y, bounds.extents.z)
                let scale = 2.0 / maxDimension
                entity.scale = [scale, scale, scale]
                print("Model scaled by factor: \(scale)")
                print("Original bounds: \(bounds)")
                print("Scaled size will be: \(bounds.extents * scale)")
            }
            
            anchor.addChild(entity)
            print("Added entity to anchor")
            
            await MainActor.run {
                arView.scene.addAnchor(anchor)
                print("Added anchor to scene")
                
                self.entity = entity
                self.anchor = anchor
                self.modelLoaded = true
                
                if let interactiveARView = arView as? InteractiveARView {
                    interactiveARView.radius = 5.0
                    interactiveARView.defaultRadius = 5.0
                    interactiveARView.target = [0, 1, -3]
                    interactiveARView.updateCameraPosition()
                    print("Camera position updated")
                }
                
                // Delay the redraw slightly to ensure everything is set up
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    print("Requesting view redraw")
                    arView.setNeedsDisplay(arView.bounds)
                }
            }
            
            print("=== Model Loading Completed ===\n")
        } catch {
            print("!!! MODEL LOADING ERROR !!!")
            print("Error description: \(error.localizedDescription)")
            print("Detailed error: \(error)")
            print("=== Model Loading Failed ===\n")
            self.modelLoaded = false
        }
        
        isCurrentlyLoading = false
    }
    
    /*
    private func centerAndScaleModel(_ entity: ModelEntity) {
        guard let boundingBox = entity.model?.mesh.bounds else { return }
        
        let scale = min(1 / boundingBox.extents.x, 1 / boundingBox.extents.y, 1 / boundingBox.extents.z)
        entity.scale = [scale, scale, scale]
        
        let centerOffset = boundingBox.center * scale
        entity.position = [-centerOffset.x, -centerOffset.y, -centerOffset.z]
        
        // Update the camera target to the center of the model
        arView.target = entity.position
    }
     */

     
}
