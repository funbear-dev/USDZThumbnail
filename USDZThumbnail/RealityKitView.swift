//
//  RealityKitView.swift
//  USDZThumbnail
//
//  Created by funbear GmbH on 23.10.2024.
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
        
        // Default lighting setup
        setupLighting(for: arViewInstance)
        
        DispatchQueue.main.async {
            self.arView = arViewInstance
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
            }
        }
    }
    
    private func setupLighting(for arView: ARView) {
        if let settings = try? JSONDecoder().decode(LightingSettings.self, from: UserDefaults.standard.data(forKey: "lightingSettings") ?? Data()) {
            switch settings.type {
            case .standard:
                setupStandardLighting(for: arView)
            case .skybox:
                Task {
                    await setupSkyboxLighting(for: arView)
                }
            }
        } else {
            setupStandardLighting(for: arView)
        }
    }
    
    private func setupStandardLighting(for arView: ARView) {
        arView.environment.lighting.intensityExponent = 1.0
        arView.environment.background = .color(.gray)
        
        let pointLight = PointLight()
        pointLight.light.intensity = 1000
        pointLight.light.attenuationRadius = 100.0
        pointLight.position = [0, 5, 0]
        let pointLightAnchor = AnchorEntity(world: .zero)
        pointLightAnchor.addChild(pointLight)
        arView.scene.addAnchor(pointLightAnchor)
        
        let directionalLight = DirectionalLight()
        directionalLight.light.intensity = 2000
        directionalLight.position = [2, 4, 2]
        directionalLight.look(at: [0, 0, 0], from: directionalLight.position, relativeTo: nil)
        
        let lightAnchor = AnchorEntity(world: .zero)
        lightAnchor.addChild(directionalLight)
        arView.scene.addAnchor(lightAnchor)
    }
    
    private func setupSkyboxLighting(for arView: ARView) async {
        let skybox = "neuer_zollhof_4k"
        if let skyboxResource = try? await EnvironmentResource.init(named: skybox) {
            await MainActor.run {
                arView.environment.lighting.resource = skyboxResource
                arView.environment.background = .skybox(skyboxResource)
            }
        } else {
            await MainActor.run {
                arView.environment.background = .color(.gray)
            }
        }
    }
}
