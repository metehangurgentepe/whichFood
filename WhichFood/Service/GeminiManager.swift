//
//  GeminiManager.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 1.03.2024.
//

import Foundation
import GoogleGenerativeAI

class GeminiManager {
    static let shared = GeminiManager()
    
    private init(){}
    
    let model = GenerativeModel(name: "gemini-pro", apiKey: APIKey.default)
    
    func fetchRecipe(prompt: String) async throws -> String? {
        let response = try await model.generateContent(prompt)
        
        if let text = response.text{
            return response.text
        } else {
            return nil
        }
    }
}
