//
//  ShowFoodViewModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 14.09.2023.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage


class ShowFoodViewModel {
    var selectedFoods = [Ingredient]()
    
    weak var delegate: ShowFoodViewDelegate?
    private(set) var isLoading: Bool = false
    private(set) var recipe : RecipeResponseModel?
    private(set) var imageURL : String?
    
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
    
    
    func generateRandomRecipeString() -> String {
        let currentLanguage = Bundle.main.preferredLocalizations.first ?? "Base"
        return "\(currentLanguage) \(LocaleKeys.ShowFood.random_prompt.rawValue.locale()) \(jsonString) \(LocaleKeys.ShowFood.json_prompt.rawValue.locale()) \(LocaleKeys.ShowFood.prompt4.rawValue.locale()) \(LocaleKeys.ShowFood.prompt5.rawValue.locale())"
    }
    
    @MainActor
    func fetchRandomRecipe() {
        Task {
            await fetchRecipe(input: generateRandomRecipeString())
        }
    }
    
    @MainActor
    func fetchFoodRecipe(foods: [Ingredient], category: [String]) {
        Task {
            await fetchRecipe(input: generateString(foods: foods, category: category))
        }
    }
    
    private func fetchRecipe(input: String) async {
        do {
            try await increaseUsageApi()
            self.delegate?.handleViewModelOutput(.setLoading(true))
            self.delegate?.handleViewModelOutput(.loadingImage(true))
            print("INPUT BURADA BURAYA BAK",input)

            // Use GeminiManager instead of SavedRecipesManager
            let response = try await GeminiManager.shared.fetchRecipe(prompt: input)
            print("RESPONSE BURADA BURAYA BAK",response ?? "nil response")

            guard let responseText = response else {
                throw WFError.invalidResponse
            }

            self.recipe = try self.getRecipe(input: responseText)
            print("RECIPE BURADA BURAYA BAK",self.recipe)
            self.delegate?.handleViewModelOutput(.showRecipe(self.recipe!))
            self.downloadImage()
            self.delegate?.handleViewModelOutput(.setLoading(false))
        } catch {
            print("Error in fetchRecipe: \(error)")
            self.delegate?.handleViewModelOutput(.showError(error as? WFError ?? .invalidResponse))
            self.delegate?.handleViewModelOutput(.setLoading(false))
        }
    }
    
    
    func generateString(foods:[Ingredient],category: [String]) -> String {
        let foodnames = foods.map { $0.name }
        let joinedCategoryStr = category.joined(separator: ", ")
        let joinedStr = foodnames.joined(separator: ", ")
        let currentLanguage = Bundle.main.preferredLocalizations.first ?? "Base"
        return "\(currentLanguage) \(LocaleKeys.ShowFood.prompt1.rawValue.locale()) \(joinedStr) \(LocaleKeys.ShowFood.prompt2.rawValue.locale()) \(joinedCategoryStr) \(LocaleKeys.ShowFood.prompt3.rawValue.locale())\(jsonString) \(LocaleKeys.ShowFood.prompt4.rawValue.locale()) \(LocaleKeys.ShowFood.prompt5.rawValue.locale())"
    }
    
    
    func saveRecipe(_ recipe: RecipeResponseModel?) async {
        self.delegate?.handleViewModelOutput(.setLoading(true))

        do{
            guard let imageURL = self.imageURL else {
                self.delegate?.handleViewModelOutput(.showError(WFError.uploadPhotoError))
                self.delegate?.handleViewModelOutput(.setLoading(false))
                return
            }

            if let recipe = self.recipe {
                try await SavedRecipesManager
                    .shared
                    .saveRecipe(name: recipe.foodName,
                                recipe: recipe.recipe,
                                ingredients: recipe.ingredients,
                                desc: recipe.description,
                                cookTime: recipe.cookTime,
                                type: recipe.type ?? "",
                                imageURL: imageURL, // Use the already uploaded image URL
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
                self.delegate?.handleViewModelOutput(.setLoading(false))
                self.delegate?.handleViewModelOutput(.successSave(true))
            }
        } catch {
            print("Error saving recipe: \(error)")
            self.delegate?.handleViewModelOutput(.showError(error as? WFError ?? .invalidResponse))
            self.delegate?.handleViewModelOutput(.setLoading(false))
        }
    }
    
    
    
    func downloadImage() {
        Task {
            do {
                // Generate image using Gemini
                let prompt = "Create a realistic, appetizing photo of \(self.recipe!.foodName). The image should look like professional food photography with good lighting and presentation."

                guard let generatedImage = try await GeminiManager.shared.generateFoodImage(prompt: prompt) else {
                    print("Failed to generate image from Gemini")
                    self.delegate?.handleViewModelOutput(.loadingImage(false))
                    return
                }

                // Upload the generated image to Firebase Storage
                self.imageURL = try await uploadGeneratedImageToFirebase(image: generatedImage, foodName: self.recipe?.foodName ?? "unknown")
                
                if let url = self.imageURL {
                    self.delegate?.handleViewModelOutput(.showImage(url))
                }
                self.delegate?.handleViewModelOutput(.loadingImage(false))
            } catch {
                print("Error in downloadImage: \(error)")
                self.delegate?.handleViewModelOutput(.showError(error as? WFError ?? .invalidResponse))
                self.delegate?.handleViewModelOutput(.loadingImage(false))
            }
        }
    }

    private func uploadGeneratedImageToFirebase(image: UIImage, foodName: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw WFError.uploadPhotoError
        }

        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imageRef = storageRef.child("foodImages/\(foodName)_\(UUID().uuidString).jpg")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await imageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await imageRef.downloadURL()

        return downloadURL.absoluteString
    }
    
    
    func increaseUsageApi() async throws{
        do{
            try await UserManager.shared.increaseApiUsage()
        } catch{
            self.delegate?.handleViewModelOutput(.showError(error as! WFError))
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
    
    func getRecipe(input: String) throws -> RecipeResponseModel? {
        guard let data = self.separateJson(json: input) else {
            print("Failed to extract JSON from response")
            throw WFError.invalidResponse
        }

        do {
            let responseModel = try JSONDecoder().decode(RecipeResponseModel.self, from: data)
            return responseModel
        } catch {
            print("JSON Decode Error: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Failed JSON: \(jsonString)")
            }
            throw WFError.invalidResponse
        }
    }
    
    func load(recipe: RecipeResponseModel) {
        self.recipe = recipe
        self.delegate?.handleViewModelOutput(.showRecipe(recipe))
        if let imageURL = recipe.imageURL {
            self.delegate?.handleViewModelOutput(.showImage(imageURL))
        }
    }
}


extension ShowFoodViewModelOutput {
    static func == (lhs: ShowFoodViewModelOutput, rhs: ShowFoodViewModelOutput) -> Bool {
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
