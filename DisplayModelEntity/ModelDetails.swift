//
//  ModelDetails.swift
//  DisplayModelEntity
//
//  Created by Stefano Rebulla on 23.10.2024.
//

import SwiftUI

struct ModelDetails: View {
    let filename: String
    let height: Float
    let diameter: Float
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Model Details")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            DetailItem(label: "Filename", value: filename)
            DetailItem(
                label: "Height",
                value: String(format: "%.3f", height)
            )
            DetailItem(
                label: "Diameter",
                value: String(format: "%.3f", diameter)
            )
            
            Spacer()
        }
        .padding()
        .frame(maxHeight: .infinity)
        .background(colorScheme == .dark ? Color(nsColor: .darkGray) : Color(nsColor: .lightGray))
    }
}

struct DetailItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

#Preview {
    ModelDetails(filename: "test.usdz", height: 1.23, diameter: 0.13)
}
