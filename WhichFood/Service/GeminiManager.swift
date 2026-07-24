//
//  GeminiManager.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 1.03.2024.
//

import AIProxy
import Foundation
import UIKit

final class GeminiManager {
    static let shared = GeminiManager()

    private static let service: GeminiService = AIProxy.geminiService(
        partialKey: "v2|fa71461b|lxT_DkOqodhfDQP7",
        serviceURL: "https://api.aiproxy.com/9de655cd/68f8f03e"
    )

    private let textModel = "gemini-2.5-flash"
    private let imageModel = "gemini-2.5-flash-image"

    private init() {}

    func fetchRecipe(prompt: String) async throws -> String? {
        let body = GeminiGenerateContentRequestBody(
            contents: [.init(parts: [.text(prompt)], role: "user")],
            generationConfig: .init(
                maxOutputTokens: 8_192,
                temperature: 0.7,
                responseMimeType: "application/json"
            )
        )

        let response = try await Self.service.generateContentRequest(
            body: body,
            model: textModel,
            secondsToWait: 60
        )
        return firstText(in: response)
    }

    func generateRecipeFromImage(image: UIImage, prompt: String) async throws -> String? {
        let resizedImage = resizeImageForAPI(image: image)
        let imageData = try makeJPEGData(from: resizedImage)
        let body = GeminiGenerateContentRequestBody(
            contents: [
                .init(
                    parts: [
                        .text(prompt),
                        .inline(data: imageData, mimeType: "image/jpeg")
                    ],
                    role: "user"
                )
            ],
            generationConfig: .init(
                maxOutputTokens: 8_192,
                temperature: 0.5,
                responseMimeType: "application/json"
            )
        )

        let response = try await Self.service.generateContentRequest(
            body: body,
            model: textModel,
            secondsToWait: 90
        )
        return firstText(in: response)
    }

    func generateFoodImage(prompt: String) async throws -> UIImage? {
        let body = GeminiGenerateContentRequestBody(
            contents: [.init(parts: [.text(prompt)], role: "user")],
            generationConfig: .init(
                imageConfig: .init(aspectRatio: "4:3"),
                responseModalities: ["Text", "Image"]
            )
        )

        let response = try await Self.service.generateContentRequest(
            body: body,
            model: imageModel,
            secondsToWait: 120
        )

        for part in response.candidates?.first?.content?.parts ?? [] {
            guard case .inlineData(_, let base64Data) = part,
                  let data = Data(base64Encoded: base64Data),
                  let image = UIImage(data: data) else {
                continue
            }
            return image
        }

        throw GeminiManagerError.missingImage
    }

    private func firstText(in response: GeminiGenerateContentResponseBody) -> String? {
        for part in response.candidates?.first?.content?.parts ?? [] {
            if case .text(let text) = part {
                return text
            }
        }
        return nil
    }

    private func makeJPEGData(from image: UIImage) throws -> Data {
        guard let imageData = image.jpegData(compressionQuality: 0.6) else {
            throw GeminiManagerError.imageEncodingFailed
        }

        let maximumSize = 15 * 1_024 * 1_024
        if imageData.count <= maximumSize {
            return imageData
        }

        guard let compressedData = image.jpegData(compressionQuality: 0.3),
              compressedData.count <= maximumSize else {
            throw GeminiManagerError.imageTooLarge
        }
        return compressedData
    }

    private func resizeImageForAPI(image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 1_024
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height)
        guard scale < 1 else { return image }

        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

private enum GeminiManagerError: LocalizedError {
    case imageEncodingFailed
    case imageTooLarge
    case missingImage

    var errorDescription: String? {
        switch self {
        case .imageEncodingFailed:
            return "The selected image could not be processed."
        case .imageTooLarge:
            return "The selected image is too large to process."
        case .missingImage:
            return "Gemini did not return an image."
        }
    }
}
