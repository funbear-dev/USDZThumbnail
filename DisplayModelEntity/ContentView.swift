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
                    diameter: modelDimensions?.diameter ?? 0
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
                    if let arView = arView as? InteractiveARView {
                        self.cameraState = arView.getCameraState()
                    }
                    
                    // Set initial dimensions with just the filename
                    self.modelDimensions = ModelDimensions(
                        filename: url.lastPathComponent,
                        height: 0,
                        diameter: 0
                    )
                    
                    // Update URL after dimensions are initialized
                    self.usdzURL = url
                    
                    // Ensure the window is key and front after drop
                    if let window = NSApp.windows.first(where: { $0.isVisible }) {
                        window.makeKey()
                        window.orderFront(nil)
                    }
                }
            }
        }
        return true
    }
}


#Preview {
    ContentView()
}
