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
    
    var body: some View {
        GeometryReader { geometry in
            let sideLength = min(geometry.size.width, geometry.size.height)
            if usdzURL != nil {
                RealityKitView(usdzURL: $usdzURL, arView: $arView)
                    .frame(width: sideLength, height: sideLength)
                    .clipped()
                    .position(x: sideLength / 2, y: sideLength / 2)
            } else {
                VStack {
                    Spacer()
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 50))
                    Text("Drag & Drop a USDZ file here...")
                        .padding()
                    Spacer()
                }
                .frame(width: sideLength, height: sideLength)
                .background(Color.secondary.opacity(0.1))
                .position(x: sideLength / 2, y: sideLength / 2)
            }
        }
        .frame(idealHeight: 0.8, alignment: .center)
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
                    self.usdzURL = url
                }
            }
        }
        return true
    }
}

struct KeyHint: View {
    
    let symbol: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: symbol)
            Text(text)
        }
        .font(.caption)
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}



#Preview {
    ContentView()
}
