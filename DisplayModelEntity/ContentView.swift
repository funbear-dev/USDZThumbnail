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
    @State private var usdzURL: URL?
    @State private var arView: ARView?
    @State private var cameraState: CameraState?
    @State private var modelDimensions: ModelDimensions?
    
    @AppStorage("saveCameraPosition") private var saveCameraPosition = false
    
    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: 0) {
                // Main viewer area - use GeometryReader to calculate size
                let viewerWidth = geometry.size.width - 200 // Subtract details pane width
                let viewerSize = min(viewerWidth, geometry.size.height)
                
                ZStack {
                    if usdzURL != nil {
                        RealityKitView(
                            usdzURL: $usdzURL,
                            arView: $arView,
                            modelDimensions: $modelDimensions
                        )
                        .frame(width: viewerSize, height: viewerSize)
                        .clipped()
                        
                        ControlsOverlay()
                            .frame(width: viewerSize, height: viewerSize)
                    } else {
                        VStack {
                            Spacer()
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 50))
                            Text("Drag & Drop a USDZ file here...")
                                .padding()
                            Spacer()
                        }
                        .frame(width: viewerSize, height: viewerSize)
                        .background(Color(nsColor: .windowBackgroundColor).opacity(0.1))
                    }
                }
                .frame(width: viewerSize, height: viewerSize)
                .background(Color(nsColor: .windowBackgroundColor))
                
                // Details pane
                ModelDetails(
                    filename: modelDimensions?.filename ?? "No model loaded",
                    height: modelDimensions?.height ?? 0,
                    diameter: modelDimensions?.diameter ?? 0,
                    onResetCamera: {
                        if let arView = arView as? InteractiveARView {
                            arView.resetCamera()
                        }
                    },
                    onApplyPreset: { state in
                        if let arView = arView as? InteractiveARView {
                            arView.setCameraState(state)
                        }
                    },
                    onSaveCurrentState: {
                        if let arView = arView as? InteractiveARView {
                            return arView.getCameraState()
                        }
                        return CameraState(radius: 6.0, azimuth: .pi/4, elevation: .pi/6, target: [0, 0, -2])
                    }
                )
                .frame(width: 200)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color(nsColor: .windowBackgroundColor))
        .onDrop(of: ["public.file-url"], isTargeted: nil, perform: handleDrop)
    }

    
    func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (urlData, error) in
            DispatchQueue.main.async {
                if let urlData = urlData as? Data,
                   let url = URL(dataRepresentation: urlData, relativeTo: nil),
                   url.pathExtension.lowercased() == "usdz" {
                    // Save current camera state if enabled
                    if let arView = arView as? InteractiveARView {
                        if saveCameraPosition {
                            let state = arView.getCameraState()
                            CameraStateManager.shared.saveState(state)
                        }
                    }
                    
                    self.modelDimensions = ModelDimensions(
                        filename: url.lastPathComponent,
                        height: 0,
                        diameter: 0
                    )
                    
                    self.usdzURL = url
                }
            }
        }
        return true
    }
}


#Preview {
    ContentView()
}
