//
//  ContentView.swift
//  DisplayModelEntity
//
//  Created by Stefano Rebulla on 21.10.2024.
//

import SwiftUI
import RealityKit
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = ViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ARViewContainer(arView: viewModel.arView)
                    .edgesIgnoringSafeArea(.all)
                
                if !viewModel.modelLoaded {
                    Text("Drag and drop a USDZ file here")
                }
            }
            .frame(width: min(geometry.size.width, geometry.size.height),
                   height: min(geometry.size.width, geometry.size.height))
            .background(Color.black.opacity(0.1))
            .onDrop(of: [UTType.usdz], isTargeted: nil) { providers -> Bool in
                guard let provider = providers.first else { return false }
                provider.loadFileRepresentation(forTypeIdentifier: UTType.usdz.identifier) { url, error in
                    guard let url = url else {
                        print("No URL provided from drop")
                        return
                    }
                    if let error = error {
                        print("Error loading dropped file: \(error.localizedDescription)")
                        return
                    }
                    
                    // Create a copy of the file in a temporary directory
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                    do {
                        if FileManager.default.fileExists(atPath: tempURL.path) {
                            try FileManager.default.removeItem(at: tempURL)
                        }
                        try FileManager.default.copyItem(at: url, to: tempURL)
                        
                        Task {
                            await viewModel.loadModel(from: tempURL)
                        }
                    } catch {
                        print("Error copying file: \(error.localizedDescription)")
                    }
                }
                return true
            }
        }
        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                viewModel.handlePanGesture(translation: value.translation)
            }
        )
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
                viewModel.handleScrollWheel(with: event)
                return event
            }
        }
    }
}

class ViewModel: ObservableObject {
    @Published var modelLoaded = false
    let arView: ARView
    private var entity: Entity?
    
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
            entity.scale = [0.8, 0.8, 0.8]  // Adjust scale here
            
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
            entity.position += SIMD3<Float>(Float(translation.width) * 0.001, -Float(translation.height) * 0.001, 0)
        } else if NSEvent.modifierFlags.contains(.command) {
            // Rotate the model
            entity.orientation *= simd_quatf(angle: Float(translation.width) * 0.01, axis: [0, 1, 0])
            entity.orientation *= simd_quatf(angle: Float(translation.height) * 0.01, axis: [1, 0, 0])
        }
    }
    
    func handleScrollWheel(with event: NSEvent) {
        guard let entity = entity else { return }
        
        let zoomFactor = 1 + Float(event.deltaY) * 0.001
        entity.scale *= SIMD3<Float>(zoomFactor, zoomFactor, zoomFactor)
    }
}

struct ARViewContainer: NSViewRepresentable {
    let arView: ARView
    
    func makeNSView(context: Context) -> ARView {
        return arView
    }
    
    func updateNSView(_ nsView: ARView, context: Context) {}
}

#Preview {
    ContentView()
}
