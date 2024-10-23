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
    
    func makeCoordinator() -> Coordinator {
        
        Coordinator(self)
    }
    
    /*
    func makeNSView(context: Context) -> ARView {
        
        let arViewInstance = InteractiveARView(frame: .zero)
        
        DispatchQueue.main.async {
            self.arView = arViewInstance
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
        
        return arViewInstance
    }
     */
    
    
    func makeNSView(context: Context) -> ARView {
        print("makeNSView: Creating new ARView instance")
        let arViewInstance = InteractiveARView(frame: .zero)
        
        // Set up default lighting
        arViewInstance.environment.lighting.intensityExponent = 1.0
        arViewInstance.environment.background = .color(.gray)
        
        // Add point light for ambient-like illumination
        let pointLight = PointLight()
        pointLight.light.intensity = 1000
        pointLight.light.attenuationRadius = 100.0  // Large radius for more uniform lighting
        pointLight.position = [0, 5, 0]  // Position above the scene
        let pointLightAnchor = AnchorEntity(world: .zero)
        pointLightAnchor.addChild(pointLight)
        arViewInstance.scene.addAnchor(pointLightAnchor)
        print("makeNSView: Added point light")
        
        // Add directional light for main illumination
        let directionalLight = DirectionalLight()
        directionalLight.light.intensity = 2000
        directionalLight.position = [2, 4, 2]
        directionalLight.look(at: [0, 0, 0], from: directionalLight.position, relativeTo: nil)
        
        let lightAnchor = AnchorEntity(world: .zero)
        lightAnchor.addChild(directionalLight)
        arViewInstance.scene.addAnchor(lightAnchor)
        print("makeNSView: Added directional light")
        
        // If we already have a URL, try to load it immediately
        if let initialURL = usdzURL {
            print("makeNSView: Initial URL detected, scheduling immediate load")
            Task {
                await context.coordinator.loadModel(into: arViewInstance, context: initialURL)
            }
        }
        
        DispatchQueue.main.async {
            self.arView = arViewInstance
        }
        
        return arViewInstance
    }
    
    
    func updateNSView(_ nsView: ARView, context: Context) {
        guard let arViewInstance = nsView as? InteractiveARView else {
            print("Error: nsView is not InteractiveARView")
            return
        }
        
        print("updateNSView called")
        print("- Current coordinator URL: \(String(describing: context.coordinator.currentURL?.path))")
        print("- New URL: \(String(describing: usdzURL?.path))")
        print("- Model loaded status: \(context.coordinator.modelLoaded)")
        
        // Only load if we have a URL and either no model is loaded or the URL has changed
        if let newURL = usdzURL,
           (!context.coordinator.modelLoaded || context.coordinator.currentURL?.path != newURL.path) {
            print("updateNSView: Initiating model load...")
            Task {
                await context.coordinator.loadModel(into: arViewInstance, context: newURL)
                context.coordinator.currentURL = newURL
            }
        }
    }
}
