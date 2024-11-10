//
//  ControlsOverlay.swift
//  DisplayModelEntity
//
//  Created by funbear GmbH on 23.10.2024.
//

import SwiftUI

struct ControlsOverlay: View {
    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 20) {
                ControlHint(
                    action: "Rotate",
                    description: "Drag mouse"
                )
                
                ControlHint(
                    action: "Pan",
                    description: "⌘ + Drag"
                )
                
                ControlHint(
                    action: "Zoom",
                    description: "⌥ + Drag"
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            .padding(.bottom, 20)
        }
    }
}

struct ControlHint: View {
    let action: String
    let description: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(action)
                .font(.caption)
                .fontWeight(.medium)
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
