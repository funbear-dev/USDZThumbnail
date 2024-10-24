//
//  CameraButton.swift
//  DisplayModelEntity
//
//  Created by Stefano Rebulla on 24.10.2024.
//

import SwiftUI


struct CameraButton: View {
    let onTakePhoto: () -> Void
    
    var body: some View {
        Button(action: onTakePhoto) {
            Image(systemName: "camera.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(.white)
                .shadow(radius: 4)
        }
        .buttonStyle(.plain)
        .padding()
    }
}
