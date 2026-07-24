//
//  ImageToTextViewModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 5.12.2023.
//

import Foundation
import UIKit
import FirebaseStorage




class ImageToTextViewModel: ImageToTextViewModelProtocol{
    var delegate: ImageToTextViewModelDelegate?
    private (set) var recipeText: String?
    
    let jsonString = """
        {
          "foodName": "",
          "ingredients": [
            ""
          ],
          "recipe": [
            ""
          ],
          "language": "",
          "cal": {
            "carbs": "",
            "fat": "",
            "protein": "",
            "totalCalories": ""
          },
          "cookTime": "",
          "prepTime": "",
          "totalTime": "",
          "difficulty": "",
          "servings": "",
          "description": "",
          "type": "",
          "cuisine": "",
          "allergens": [
            ""
          ],
          "tags": [
            ""
          ],
          "nutritionalInfo": {
            "sugar": "",
            "fiber": "",
            "sodium": "",
            "cholesterol": ""
          },
          "tips": [
            ""
          ]
        }
        """
    
    func uploadRecipePhoto(image: UIImage) async {
        delegate?.handleViewModelOutput(.setLoading(true))

        // Direkt olarak Gemini ile image analizi yap
        await generateRecipeFromImage(image: image)
    }
    
    func generateRecipeFromImage(image: UIImage) async {
        delegate?.handleViewModelOutput(.setLoading(true))

        let currentLanguage = Bundle.main.preferredLocalizations.first ?? "en"
        let languageText = currentLanguage == "tr" ? "Türkçe" : "English"

        let input = """
        Based on what you see in this food image, create a complete detailed recipe in \(languageText) for this dish.

        Please provide:
        - Food name and description
        - Complete ingredients list with quantities
        - Step-by-step cooking instructions
        - Cooking times (prep, cook, total)
        - Difficulty level (easy, medium, hard)
        - Number of servings
        - Cuisine type
        - Nutritional information (calories, carbs, fat, protein, sugar, fiber, sodium, cholesterol)
        - Allergens if any
        - Tags/categories
        - Chef's tips for better results

        Return the response in this exact JSON format:
        \(self.jsonString)

        Make sure the recipe is realistic and matches what you see in the image. Provide detailed nutritional estimates and helpful cooking tips. If you cannot clearly identify the food, provide a general recipe for what appears to be the closest match.
        """

        do {
            let response = try await GeminiManager.shared.generateRecipeFromImage(image: image, prompt: input)

            guard let responseText = response else {
                let error = NSError(domain: "GeminiManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response from Gemini API"])
                self.delegate?.handleViewModelOutput(.showError(error))
                self.delegate?.handleViewModelOutput(.setLoading(false))
                return
            }

            print("Gemini Response: \(responseText)")

            guard let data = self.separateJson(json: responseText) else {
                let error = NSError(domain: "GeminiManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to extract JSON from Gemini response"])
                self.delegate?.handleViewModelOutput(.showError(error))
                self.delegate?.handleViewModelOutput(.setLoading(false))
                return
            }

            do {
                let responseModel = try JSONDecoder().decode(RecipeResponseModel.self, from: data)

                // Firebase Storage'a resmi yükle
                let imageUrl = await uploadImageToStorage(image: image)

                let recipe = RecipeResponseModel(
                    foodName: responseModel.foodName,
                    ingredients: responseModel.ingredients,
                    recipe: responseModel.recipe,
                    cookTime: responseModel.cookTime,
                    prepTime: responseModel.prepTime,
                    totalTime: responseModel.totalTime,
                    difficulty: responseModel.difficulty,
                    servings: responseModel.servings,
                    description: responseModel.description,
                    type: responseModel.type ?? "general",
                    cuisine: responseModel.cuisine,
                    allergens: responseModel.allergens,
                    tags: responseModel.tags,
                    cal: responseModel.cal,
                    nutritionalInfo: responseModel.nutritionalInfo,
                    tips: responseModel.tips,
                    imageURL: imageUrl
                )
                self.delegate?.handleViewModelOutput(.setLoading(false))
                self.delegate?.handleViewModelOutput(.showRecipe(recipe))
            } catch {
                print("JSON Decode Error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Failed JSON: \(jsonString)")
                }
                let parseError = NSError(domain: "GeminiManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse recipe data from response"])
                self.delegate?.handleViewModelOutput(.showError(parseError))
                self.delegate?.handleViewModelOutput(.setLoading(false))
            }
        } catch {
            print("Gemini API Error: \(error.localizedDescription)")
            self.delegate?.handleViewModelOutput(.showError(error))
            self.delegate?.handleViewModelOutput(.setLoading(false))
        }
    }

    private func uploadImageToStorage(image: UIImage) async -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            return nil
        }

        let storage = Storage.storage()
        let storageRef = storage.reference()
        let recipePhotoRef = storageRef.child("food_photos").child(UUID().uuidString + ".jpg")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        do {
            _ = try await recipePhotoRef.putDataAsync(imageData, metadata: metadata)
            let downloadURL = try await recipePhotoRef.downloadURL()
            return downloadURL.absoluteString
        } catch {
            print("Error uploading image: \(error.localizedDescription)")
            return nil
        }
    }
    
    func saveRecipe(recipe: RecipeResponseModel?) async{
        if let recipe = recipe{
            do{
                try await SavedRecipesManager.shared.saveRecipe(
                    name: recipe.foodName,
                    recipe: recipe.recipe,
                    ingredients: recipe.ingredients,
                    desc: recipe.description,
                    cookTime: recipe.cookTime,
                    type: recipe.type ?? "general",
                    imageURL: recipe.imageURL ?? "", // Default empty string if no image URL
                    prepTime: recipe.prepTime,
                    totalTime: recipe.totalTime,
                    difficulty: recipe.difficulty,
                    servings: recipe.servings,
                    cuisine: recipe.cuisine,
                    tags: recipe.tags,
                    cal: recipe.cal,
                    nutritionalInfo: recipe.nutritionalInfo,
                    allergens: recipe.allergens,
                    tips: recipe.tips
                )
                self.delegate?.handleViewModelOutput(.saved)
            } catch{
                self.delegate?.handleViewModelOutput(.showError(error))
            }
        } else {
            let error = NSError(domain: "ImageToTextViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Recipe is nil"])
            self.delegate?.handleViewModelOutput(.showError(error))
        }
    }
    
    func separateJson(json: String) -> Data? {
        // Try to find JSON within the response
        let cleanedJson = json.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if it's already valid JSON
        if cleanedJson.hasPrefix("{") && cleanedJson.hasSuffix("}") {
            return cleanedJson.data(using: .utf8)
        }

        // Look for JSON within markdown code blocks
        if let jsonStartRange = cleanedJson.range(of: "```json"),
           let jsonEndRange = cleanedJson.range(of: "```", range: jsonStartRange.upperBound..<cleanedJson.endIndex) {
            let jsonContent = String(cleanedJson[jsonStartRange.upperBound..<jsonEndRange.lowerBound])
            return jsonContent.trimmingCharacters(in: .whitespacesAndNewlines).data(using: .utf8)
        }

        // Look for any JSON object in the text
        if let startIndex = cleanedJson.range(of: "{"),
           let endIndex = cleanedJson.range(of: "}", options: .backwards) {
            let jsonString = String(cleanedJson[startIndex.lowerBound...endIndex.upperBound])
            return jsonString.data(using: .utf8)
        }

        return nil
    }
}

extension ImageToTextViewModeOutput {
    static func == (lhs: ImageToTextViewModeOutput, rhs: ImageToTextViewModeOutput) -> Bool {
        switch (lhs, rhs) {
        case (.setLoading(let a), .setLoading(let b)):
            return a == b
        case (.showRecipe(let a), .showRecipe(let b)):
            return a == b
        default:
            return false
        }
    }
}
