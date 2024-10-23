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
    private var isCurrentlyLoading = false
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
        guard !isCurrentlyLoading else { return }
        isCurrentlyLoading = true
        
        do {
            let entity = try await ModelEntity.init(contentsOf: context)
            
            await MainActor.run {
                arView.scene.anchors.forEach { anchor in
                    if anchor.name == "ModelAnchor" {
                        arView.scene.removeAnchor(anchor)
                    }
                }
            }
            
            let anchor = AnchorEntity(world: [0, 1, -3])
            anchor.name = "ModelAnchor"
            
            if let bounds = entity.model?.mesh.bounds {
                let maxDimension = max(bounds.extents.x, bounds.extents.y, bounds.extents.z)
                let scale = 2.0 / maxDimension
                entity.scale = [scale, scale, scale]
            }
            
            anchor.addChild(entity)
            
            await MainActor.run {
                arView.scene.addAnchor(anchor)
                
                self.entity = entity
                self.anchor = anchor
                self.modelLoaded = true
                
                if let interactiveARView = arView as? InteractiveARView {
                    interactiveARView.radius = 5.0
                    interactiveARView.defaultRadius = 5.0
                    interactiveARView.target = [0, 1, -3]
                    interactiveARView.updateCameraPosition()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    arView.setNeedsDisplay(arView.bounds)
                }
            }
        } catch {
            self.modelLoaded = false
        }
        
        isCurrentlyLoading = false
    }
}
