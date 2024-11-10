//
//  Coordinator.swift
//  DisplayModelEntity
//
//  Created by funbear GmbH on 23.10.2024.
//

import Foundation
import RealityKit


class Coordinator {
    @Published var modelLoaded = false
    private var isCurrentlyLoading = false
    private let viewSize: Float = 4.0
    var parent: RealityKitView
    var currentURL: URL?
    var entity: ModelEntity?
    private var anchor: AnchorEntity?
    
    init(_ parent: RealityKitView) {
        self.parent = parent
        self.currentURL = parent.usdzURL
        self.modelLoaded = false
        self.isCurrentlyLoading = false
    }
    
    @MainActor
    func loadModel(into arView: ARView, context: URL) async {
        
        guard !isCurrentlyLoading else { return }
        isCurrentlyLoading = true
        
        do {
            let entity = try await ModelEntity.init(contentsOf: context)
            
            // Store the entity first so it's available for bounds checking
            self.entity = entity
            
            guard let bounds = entity.model?.mesh.bounds else {
                print("Error: Unable to get model bounds")
                return
            }
            
            // Calculate raw dimensions for the details panel
            let rawHeight = abs(bounds.max.y - bounds.min.y)
            let rawDiameterX = abs(bounds.max.x - bounds.min.x)
            let rawDiameterZ = abs(bounds.max.z - bounds.min.z)
            let rawDiameter = max(rawDiameterX, rawDiameterZ)
            
            parent.$modelDimensions.wrappedValue = .init(
                filename: context.lastPathComponent,
                height: rawHeight,
                diameter: rawDiameter
            )
            
            // Calculate optimal scale and position
            let centerOffset = bounds.center
            
            // Calculate scale based on the largest dimension to fit the view
            let maxDimension = max(
                bounds.extents.x,
                bounds.extents.y,
                bounds.extents.z
            )
            let scale = viewSize / maxDimension
            entity.scale = [scale, scale, scale]
            
            // Position the model so it's centered in view
            entity.position = [-centerOffset.x * scale,
                                -centerOffset.y * scale,
                                -centerOffset.z * scale - viewSize/2]
            
            // Clean up existing content
            arView.scene.anchors.forEach { anchor in
                if anchor.name == "ModelAnchor" {
                    arView.scene.removeAnchor(anchor)
                }
            }
            
            // Create anchor at world origin
            let anchor = AnchorEntity(world: .zero)
            anchor.name = "ModelAnchor"
            anchor.addChild(entity)
            arView.scene.addAnchor(anchor)
            
            self.anchor = anchor
            self.modelLoaded = true
            
            // Update camera to frame the model
            if let interactiveARView = arView as? InteractiveARView {
                // Check if we should use saved camera position
                if UserDefaults.standard.bool(forKey: "saveCameraPosition"),
                   let savedState = CameraStateManager.shared.loadState() {
                    interactiveARView.setCameraState(savedState)
                } else {
                    // Use default camera position
                    let initialRadius: Float = 6.0
                    interactiveARView.defaultRadius = initialRadius
                    interactiveARView.radius = initialRadius
                    interactiveARView.elevation = .pi / 6
                    interactiveARView.azimuth = .pi / 4
                    interactiveARView.target = [0, 0, -viewSize/2]
                    interactiveARView.updateCameraPosition()
                }
            }
            
        } catch {
            print("Error loading model: \(error)")
            self.modelLoaded = false
        }
        
        isCurrentlyLoading = false
    }
}
