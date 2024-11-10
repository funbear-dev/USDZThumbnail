//
//  ContentView.swift
//  USDZThumbnail
//
//  Created by funbear GmbH on 21.10.2024.
//

import SwiftUI
import RealityKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var usdzURL: URL?
    @State private var arView: ARView?
    @State private var cameraState: CameraState?
    @State private var modelDimensions: ModelDimensions?
    @State private var showingSavePanel = false
    @State private var capturedImage: NSImage?
    @State private var showingSaveError = false
    @State private var saveError: String = ""
    
    @AppStorage("saveCameraPosition") private var saveCameraPosition = false
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Main viewer area
                GeometryReader { viewerGeometry in
                    let viewerSize = min(viewerGeometry.size.width, viewerGeometry.size.height)
                    
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
                            
                            // Camera button positioned relative to the AR view
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    CameraButton {
                                        capturePhoto()
                                    }
                                }
                            }
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
                    .position(x: viewerSize/2, y: viewerSize/2)
                }
                
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
                    },
                    currentModelURL: $usdzURL  // Pass the binding
                )
                
                .frame(width: 200)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color(nsColor: .windowBackgroundColor))
        .onDrop(of: ["public.file-url"], isTargeted: nil, perform: handleDrop)
        .alert("Error", isPresented: $showingSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveError)
        }
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
    
    
    private func capturePhoto() {
        guard let arView = arView else { return }
        
        let settings = try? JSONDecoder().decode(PhotoSettings.self, from: UserDefaults.standard.data(forKey: "photoSettings") ?? Data())
        let resolution = settings?.resolution ?? .res1024
        let useHDR = settings?.useHDR ?? false
        
        if let sound = NSSound(named: "camera-shutter") {
            sound.play()
        }
        
        arView.snapshot(saveToHDR: useHDR) { image in
            guard let image = image else {
                DispatchQueue.main.async {
                    self.saveError = "Failed to capture snapshot"
                    self.showingSaveError = true
                }
                return
            }
            
            let croppedImage = cropToSquare(image: image)
            let targetSize = NSSize(width: resolution.rawValue, height: resolution.rawValue)
            let resizedImage = resizeImage(image: croppedImage, targetSize: targetSize)
            
            DispatchQueue.main.async {
                self.capturedImage = resizedImage
                self.presentSavePanel()
            }
        }
    }
    
    
    func cropToSquare(image: NSImage) -> NSImage {
        let originalSize = image.size
        let sideLength = min(originalSize.width, originalSize.height)
        let x = (originalSize.width - sideLength) / 2
        let y = (originalSize.height - sideLength) / 2
        let cropRect = NSRect(x: x, y: y, width: sideLength, height: sideLength)

        let newImage = NSImage(size: NSSize(width: sideLength, height: sideLength))
        newImage.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: newImage.size),
            from: cropRect,
            operation: .copy,
            fraction: 1.0
        )
        newImage.unlockFocus()
        return newImage
    }

    
    func resizeImage(image: NSImage, targetSize: NSSize) -> NSImage {
        let newImage = NSImage(size: targetSize)
        newImage.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1.0
        )
        newImage.unlockFocus()
        return newImage
    }
    
    
    private func savePhoto() {
        guard let image = capturedImage else { return }
        
        let savePanel = NSSavePanel()
        let settings = try? JSONDecoder().decode(PhotoSettings.self, from: UserDefaults.standard.data(forKey: "photoSettings") ?? Data())
        let format = settings?.format ?? .png
        
        // Get model filename without extension
        let modelName = modelDimensions?.filename.deletingPathExtension ?? "capture"
        
        savePanel.allowedContentTypes = [format == .png ? .png : .jpeg]
        savePanel.nameFieldStringValue = "\(modelName).\(format.fileExtension)"
        
        // Set initial directory to Pictures folder
        if let picturesURL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first {
            savePanel.directoryURL = picturesURL
        }
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                if let tiffData = image.tiffRepresentation,
                   let bitmap = NSBitmapImageRep(data: tiffData) {
                    let data: Data?
                    
                    switch format {
                    case .png:
                        data = bitmap.representation(using: .png, properties: [:])
                    case .jpeg:
                        data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
                    }
                    
                    if let data = data {
                        do {
                            try data.write(to: url)
                            print("Image saved successfully to: \(url.path)")
                            
                            // Reveal in Finder
                            NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
                        } catch {
                            DispatchQueue.main.async {
                                saveError = "Failed to save image: \(error.localizedDescription)"
                                showingSaveError = true
                            }
                        }
                    }
                }
            }
            showingSavePanel = false
        }
    }
    
    private func presentSavePanel() {
        guard let image = capturedImage else { return }
        
        let savePanel = NSSavePanel()
        let settings = try? JSONDecoder().decode(PhotoSettings.self, from: UserDefaults.standard.data(forKey: "photoSettings") ?? Data())
        let format = settings?.format ?? .png
        
        let modelName = modelDimensions?.filename.deletingPathExtension ?? "capture"
        
        savePanel.allowedContentTypes = [format == .png ? .png : .jpeg]
        savePanel.nameFieldStringValue = "\(modelName).\(format.fileExtension)"
        
        if let picturesURL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first {
            savePanel.directoryURL = picturesURL
        }
        
        NSApp.activate(ignoringOtherApps: true)
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                if let tiffData = image.tiffRepresentation,
                   let bitmap = NSBitmapImageRep(data: tiffData) {
                    let data: Data?
                    
                    switch format {
                    case .png:
                        data = bitmap.representation(using: .png, properties: [:])
                    case .jpeg:
                        data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
                    }
                    
                    if let data = data {
                        do {
                            try data.write(to: url)
                            NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
                        } catch {
                            DispatchQueue.main.async {
                                self.saveError = "Failed to save image: \(error.localizedDescription)"
                                self.showingSaveError = true
                            }
                        }
                    }
                }
            }
        }
    }
}


// Add extension for String to handle filename
extension String {
    var deletingPathExtension: String {
        (self as NSString).deletingPathExtension
    }
}


#Preview {
    ContentView()
}
