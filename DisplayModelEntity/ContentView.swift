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
                ARViewContainer(viewModel: viewModel)
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
                provider.loadObject(ofClass: URL.self) { url, error in
                    if let url = url {
                        viewModel.loadModel(from: url)
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
    var arView: ARView?
    private var entity: Entity?
    private var initialEntityTransform: Transform?
    
    init() {
        setupARView()
    }
    
    private func setupARView() {
        let arView = ARView(frame: .zero)
        arView.environment.background = .color(.clear)
        self.arView = arView
    }
    
    func loadModel(from url: URL) {
        Task { @MainActor in
            do {
                let model = try await Entity.init(contentsOf: url)
                
                // Remove existing entities
                arView?.scene.anchors.removeAll()
                
                // Add the new entity
                let anchor = AnchorEntity(world: .zero)
                anchor.addChild(model)
                arView?.scene.addAnchor(anchor)
                
                // Position the model in front of the camera
                model.position = [0, 0, -2]
                model.scale = [0.5, 0.5, 0.5]  // Adjust scale if needed
                
                self.entity = model
                self.initialEntityTransform = model.transform
                self.modelLoaded = true
            } catch {
                print("Failed to load model: \(error.localizedDescription)")
            }
        }
    }
    
    func handlePanGesture(translation: CGSize) {
        guard let entity = entity else { return }
        
        if NSEvent.modifierFlags.contains(.option) {
            // Pan (translate) the model
            entity.position += SIMD3<Float>(Float(translation.width) * 0.01, -Float(translation.height) * 0.01, 0)
        } else if NSEvent.modifierFlags.contains(.command) {
            // Rotate the model
            entity.orientation *= simd_quatf(angle: Float(translation.width) * 0.01, axis: [0, 1, 0])
            entity.orientation *= simd_quatf(angle: Float(translation.height) * 0.01, axis: [1, 0, 0])
        }
    }
    
    func handleScrollWheel(with event: NSEvent) {
        guard let entity = entity else { return }
        
        let zoomFactor = 1 + Float(event.deltaY) * 0.01
        entity.scale *= SIMD3<Float>(zoomFactor, zoomFactor, zoomFactor)
    }
}

struct ARViewContainer: NSViewRepresentable {
    @ObservedObject var viewModel: ViewModel
    
    func makeNSView(context: Context) -> ARView {
        return viewModel.arView ?? ARView(frame: .zero)
    }
    
    func updateNSView(_ nsView: ARView, context: Context) {
        // Update the view if needed
    }
}

#Preview {
    ContentView()
}
