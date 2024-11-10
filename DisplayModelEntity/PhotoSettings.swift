//
//  PhotoSettings.swift
//  DisplayModelEntity
//
//  Created by funbear GmbH on 24.10.2024.
//

import Foundation


struct PhotoSettings: Codable {
    enum Resolution: Int, CaseIterable, Identifiable, Codable {
        case res256 = 256
        case res512 = 512
        case res1024 = 1024
        case res2048 = 2048
        
        var id: Int { rawValue }
        var description: String { "\(rawValue)×\(rawValue)" }
    }
    
    enum ImageFormat: String, CaseIterable, Identifiable, Codable {
        case png = "PNG"
        case jpeg = "JPEG"
        
        var id: String { rawValue }
        var fileExtension: String {
            switch self {
            case .png: return "png"
            case .jpeg: return "jpg"
            }
        }
    }
    
    var resolution: Resolution
    var format: ImageFormat
    var useHDR: Bool
    
    static let defaultSettings = PhotoSettings(
        resolution: .res256,
        format: .png,
        useHDR: true
    )
}

struct LightingSettings: Codable {
    enum LightingType: String, CaseIterable, Identifiable, Codable {
        case standard
        case skybox
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .standard: return "Standard Lighting"
            case .skybox: return "Environment Lighting"
            }
        }
    }
    
    var type: LightingType
    
    static let defaultSettings = LightingSettings(type: .standard)
}
