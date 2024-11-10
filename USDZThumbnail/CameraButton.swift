//
//  CameraButton.swift
//  USDZThumbnail
//
//  Created by funbear GmbH on 24.10.2024.
//

import SwiftUI


struct CameraButton: View {
    let onTakePhoto: () -> Void
    
    var body: some View {
        Button(action: onTakePhoto) {
            Image(systemName: "camera.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(.white)
                .shadow(radius: 4)
        }
        .buttonStyle(.plain)
        .padding(20)  // Increased padding for better touch target
    }
}
