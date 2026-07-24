// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let textModel = try? JSONDecoder().decode(TextModel.self, from: jsonData)

import Foundation

struct TextModel: Codable {
    let version: String
    let objecturl: String
    let message: String
    let resource: String
    let TextDetections: [TextDetection]
}

struct TextDetection: Codable {
    let DetectedText: String
    let `Type`: String
    let Id: Int
    let Confidence: Double
    let Geometry: Geometry
}

struct Geometry: Codable {
    let BoundingBox: BoundingBox
    let Polygon: [Polygon]
}

struct BoundingBox: Codable {
    let Width: Double
    let Height: Double
    let Left: Double
    let Top: Double
}

struct Polygon: Codable {
    let X: Double
    let Y: Double
}
