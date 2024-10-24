//
//  InteractiveARView.swift
//  ModelScreenShot2
//
//  Created by Stefano Rebulla on 20.10.2024.
//


import RealityKit
import AppKit

class InteractiveARView: ARView {
    
    var lastMouseLocation: CGPoint = .zero
    var cameraAnchor = AnchorEntity(world: .zero)

    // Spherical coordinates for camera position
    var radius: Float = 2.0
    var defaultRadius: Float?
    var azimuth: Float = 0.0
    var elevation: Float = .pi / 6

    // Target point the camera looks at
    var target: SIMD3<Float> = .zero

    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupCamera()
    }

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }

    private func setupCamera() {
        let camera = PerspectiveCamera()
        updateCameraPosition()
        cameraAnchor.addChild(camera)
        self.scene.addAnchor(cameraAnchor)
    }

    func updateCameraPosition() {
        let x = target.x + radius * cos(elevation) * sin(azimuth)
        let y = target.y + radius * sin(elevation)
        let z = target.z + radius * cos(elevation) * cos(azimuth)
        
        let cameraPosition = SIMD3<Float>(x, y, z)
        cameraAnchor.position = cameraPosition
        cameraAnchor.look(at: target, from: cameraAnchor.position, relativeTo: nil)
    }

    func resetCamera() {
        radius = defaultRadius ?? 6.0
        azimuth = .pi / 4
        elevation = .pi / 6
        target = [0, 0, -2]
        updateCameraPosition()
    }
    
    // Method to get the current camera state
    func getCameraState() -> CameraState {
        
        return CameraState(radius: radius, azimuth: azimuth, elevation: elevation, target: target)
    }

    // Method to set the camera state
    func setCameraState(_ state: CameraState) {
        
        self.radius = state.radius
        self.azimuth = state.azimuth
        self.elevation = state.elevation
        self.target = state.target
        updateCameraPosition()
    }
    
    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        
        lastMouseLocation = convert(event.locationInWindow, from: nil)
    }

    override func mouseDragged(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        let deltaX = Float(location.x - lastMouseLocation.x)
        let deltaY = Float(location.y - lastMouseLocation.y)
        lastMouseLocation = location
        
        let commandKeyPressed = event.modifierFlags.contains(.command)
        let optionKeyPressed = event.modifierFlags.contains(.option)
        
        if commandKeyPressed {
            panCamera(deltaX: -deltaX, deltaY: -deltaY)  // Inverted both deltas
        } else if optionKeyPressed {
            zoomCamera(deltaY: -deltaY)  // Inverted deltaY
        } else {
            rotateCamera(deltaX: deltaX, deltaY: deltaY)  // Keep as is for standard orbit controls
        }
    }


    // MARK: - Interaction Methods

    private func rotateCamera(deltaX: Float, deltaY: Float) {
        let sensitivity: Float = 0.005
        azimuth -= deltaX * sensitivity  // Keep negative for natural rotation
        elevation += deltaY * sensitivity // Keep positive for natural up/down
        
        let maxElevation = Float.pi / 2 - 0.01
        let minElevation = -Float.pi / 2 + 0.01
        elevation = max(min(elevation, maxElevation), minElevation)
        
        updateCameraPosition()
    }

    private func panCamera(deltaX: Float, deltaY: Float) {
        let sensitivity: Float = 0.002
        // Calculate right vector based on current camera orientation
        let right = SIMD3<Float>(sin(azimuth - Float.pi / 2), 0, cos(azimuth - Float.pi / 2))  // Removed negative
        let up = SIMD3<Float>(0, 1, 0)
        
        // Apply movement - deltaX moves along right vector, deltaY moves along up vector
        let panOffset = (deltaX * sensitivity) * right + (deltaY * sensitivity) * up
        target += panOffset
        
        updateCameraPosition()
    }


    private func zoomCamera(deltaY: Float) {
        let sensitivity: Float = 0.01
        if defaultRadius == nil {
            defaultRadius = radius
        }
        
        // Allow much closer zoom for detailed inspection
        radius += deltaY * sensitivity
        radius = max(radius, 0.1)  // Allow very close zoom
        radius = min(radius, 15.0) // Reasonable maximum distance
        
        updateCameraPosition()
    }
}

struct CameraState: Codable {
    
    var radius: Float
    var azimuth: Float
    var elevation: Float
    var target: SIMD3<Float>
}
