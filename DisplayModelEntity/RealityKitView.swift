//
//  RealityKitView.swift
//  DisplayModelEntity
//
//  Created by Stefano Rebulla on 23.10.2024.
//

import SwiftUI
import RealityKit


struct RealityKitView: NSViewRepresentable {
    
    @Binding var usdzURL: URL?
    @Binding var arView: ARView?
    @Binding var modelDimensions: ModelDimensions?
    
    func makeCoordinator() -> Coordinator {
        
        Coordinator(self)
    }
    
    
    // TODO: - Add default/loaded lighting, from EXR or from standard Light
    /*
    let skybox = "neuer_zollhof_4k.exr"
    if let skyboxResource = try? await EnvironmentResource.init(named: skybox) {
        
        print("Loading Skybox with name: \(skybox)")
        arView.environment.lighting.resource = skyboxResource
        arView.environment.background = .skybox(skyboxResource)
    } else {
        arView.environment.background = .color(.clear)
    }
     */
    
    
    func makeNSView(context: Context) -> ARView {
        let arViewInstance = InteractiveARView(frame: .zero)
        
        // Set up default lighting
        arViewInstance.environment.lighting.intensityExponent = 1.0
        arViewInstance.environment.background = .color(.gray)
        
        // Add point light for better illumination
        let pointLight = PointLight()
        pointLight.light.intensity = 1000
        pointLight.light.attenuationRadius = 100.0
        pointLight.position = [0, 5, 0]
        let pointLightAnchor = AnchorEntity(world: .zero)
        pointLightAnchor.addChild(pointLight)
        arViewInstance.scene.addAnchor(pointLightAnchor)
        
        // Add directional light for shadows and overall illumination
        let directionalLight = DirectionalLight()
        directionalLight.light.intensity = 2000
        directionalLight.position = [2, 4, 2]
        directionalLight.look(at: [0, 0, 0], from: directionalLight.position, relativeTo: nil)
        
        let lightAnchor = AnchorEntity(world: .zero)
        lightAnchor.addChild(directionalLight)
        arViewInstance.scene.addAnchor(lightAnchor)
        
        DispatchQueue.main.async {
            self.arView = arViewInstance
            
            // Make the window key and make the view first responder
            if let window = arViewInstance.window {
                window.makeFirstResponder(arViewInstance)
                window.makeKey()
            }
        }
        
        return arViewInstance
    }
    
    func updateNSView(_ nsView: ARView, context: Context) {
        guard let arViewInstance = nsView as? InteractiveARView else { return }
        
        if let newURL = usdzURL,
           (!context.coordinator.modelLoaded || context.coordinator.currentURL?.path != newURL.path) {
            Task {
                await context.coordinator.loadModel(into: arViewInstance, context: newURL)
                context.coordinator.currentURL = newURL
                
                // Ensure window focus and first responder status after loading
                await MainActor.run {
                    if let window = nsView.window {
                        window.makeFirstResponder(nsView)
                        window.makeKey()
                    }
                }
            }
        }
    }
}
