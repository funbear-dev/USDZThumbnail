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

    public func resetCamera() {
        radius = defaultRadius ?? 2.0
        azimuth = 0.0
        elevation = .pi / 6
        target = .zero
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

        // Check for modifier keys
        let commandKeyPressed = event.modifierFlags.contains(.command)
        let optionKeyPressed = event.modifierFlags.contains(.option)

        if commandKeyPressed {
            // Pan the camera
            panCamera(deltaX: deltaX, deltaY: deltaY)
        } else if optionKeyPressed {
            // Zoom the camera
            zoomCamera(deltaY: deltaY)
        } else {
            // Rotate the camera around the model
            rotateCamera(deltaX: deltaX, deltaY: deltaY)
        }
    }


    // MARK: - Interaction Methods

    private func rotateCamera(deltaX: Float, deltaY: Float) {
        
        // Adjust the azimuth and elevation angles
        let sensitivity: Float = 0.005
        azimuth -= deltaX * sensitivity
        elevation += deltaY * sensitivity

        // Clamp elevation to avoid flipping over the top
        let maxElevation = Float.pi / 2 - 0.01  // Just below 90 degrees
        let minElevation = -Float.pi / 2 + 0.01 // Just above -90 degrees
        elevation = max(min(elevation, maxElevation), minElevation)

        updateCameraPosition()
    }

    private func panCamera(deltaX: Float, deltaY: Float) {
        
        // Pan the camera by adjusting the target position
        let sensitivity: Float = 0.002

        // Calculate right and up vectors relative to the current camera orientation
        let right = SIMD3<Float>(-sin(azimuth - Float.pi / 2), 0, -cos(azimuth - Float.pi / 2)) // Reverse direction for correct panning
        let up = SIMD3<Float>(0, 1, 0)

        let panOffset = (deltaX * sensitivity) * right + (-deltaY * sensitivity) * up // Reverse deltaY

        target += panOffset

        updateCameraPosition()
    }


    private func zoomCamera(deltaY: Float) {
        let sensitivity: Float = 0.01
        
        // If defaultRadius is set, ensure it is only set once when model is loaded
        if defaultRadius == nil {
            defaultRadius = radius
        }

        // Adjust the radius based on zoom input without limiting the minimum zoom level
        radius += deltaY * sensitivity
        radius = max(radius, 0.1) // Prevent the camera from zooming into negative space but allow very close zooming

        updateCameraPosition()
    }
}

struct CameraState {
    
    var radius: Float
    var azimuth: Float
    var elevation: Float
    var target: SIMD3<Float>
}
