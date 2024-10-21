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
                    VStack {
                        Spacer()
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 50))
                        Text("Drag & Drop a USDZ file here...")
                            .padding()
                        Spacer()
                    }
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
