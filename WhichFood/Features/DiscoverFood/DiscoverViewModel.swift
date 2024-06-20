//
//  DiscoverViewModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 1.03.2024.
//

import Foundation
import UIKit
import FirebaseStorage

enum DiscoverFoodViewModelOutput: Equatable {
    case setLoading(Bool)
    case showRecipe(RecipeResponseModel)
    case showError(Error)
    case saveRecipe
    case showImage(String)
    case loadingPhoto(Bool)
    case successSave
}

protocol DiscoverFoodViewModelProtocol {
    var delegate: DiscoverFoodViewDelegate? { get set }
    func fetchFoodRecipe(foods: [Ingredient],category: [String])
    func saveRecipe()
}

class DiscoverFoodViewModel {
    private (set) var recipe: RecipeResponseModel?
    private (set) var imageURL: String?
    weak var delegate: DiscoverFoodViewDelegate?
    
    let jsonString = """
        {
          "foodName": "",
          "ingredients": [
            "",
          ],
          "recipe": [
            ""
          ],
          "cookTime": "",
          "description": "",
            "type:": ""
        }
        """
    
    
    func generateString() -> String {
        let currentLanguage = Bundle.main.preferredLocalizations.first ?? "Base"
        return "\(currentLanguage) \(LocaleKeys.ShowFood.random_prompt.rawValue.locale()) \(jsonString) \(LocaleKeys.ShowFood.json_prompt.rawValue.locale()) \(LocaleKeys.ShowFood.prompt4.rawValue.locale()) \(LocaleKeys.ShowFood.prompt5.rawValue.locale())"
    }
    
    
    @MainActor
    func postInput() {
        self.delegate?.handleViewModelOutput(.setLoading(true))
        self.delegate?.handleViewModelOutput(.loadingPhoto(true))
        Task { [weak self] in
            guard let self = self else { return }
            do{
                let response = try await SavedRecipesManager.shared.postData(input: self.generateString())
                self.recipe = try getRecipe(input: response)
                DispatchQueue.main.async{
                    if let recipe = self.recipe {
                        self.delegate?.handleViewModelOutput(.showRecipe(recipe))
                        self.downloadImage()
                    }
                }
                self.delegate?.handleViewModelOutput(.setLoading(false))
            } catch {
                self.delegate?.handleViewModelOutput(.showError(error))
                self.delegate?.handleViewModelOutput(.setLoading(false))
            }
        }
    }
    
    
    func downloadImage() {
        Task {
            do {
                self.imageURL = try await SavedRecipesManager.shared.generateImage(input: "\(self.recipe!.foodName) realistic food")
                if let url = self.imageURL {
                    self.delegate?.handleViewModelOutput(.showImage(url))
                }
                self.delegate?.handleViewModelOutput(.loadingPhoto(false))
            } catch {
                self.delegate?.handleViewModelOutput(.showError(error))
                self.delegate?.handleViewModelOutput(.loadingPhoto(false))
            }
        }
    }
    
    
    func postImageToFirebase(imageURL: String) throws {
        guard let imageData = try? Data(contentsOf: URL(string: imageURL)!) else {
            throw WFError.uploadPhotoError
        }
        
        let storageRef = Storage.storage().reference().child("foodImages/\(recipe!.foodName)")
        
        let _ = storageRef.putData(imageData)
    }
    
    
    func saveRecipe(_ recipe: RecipeResponseModel?) {
        Task { [weak self] in
            guard let self = self else { return }
            self.delegate?.handleViewModelOutput(.setLoading(true))
            
            do {
                try postImageToFirebase(imageURL: self.imageURL ?? "")
                
                let storageRef = Storage.storage().reference().child("foodImages/\(recipe!.foodName)")
                
                try await Task.sleep(nanoseconds: 3 * 1_000_000_000)
                
                do {
                    let downloadURL = try await storageRef.downloadURL()
                    
                    if let recipe = self.recipe {
                        try await SavedRecipesManager
                            .shared
                            .saveRecipe(name: recipe.foodName,
                                        recipe: recipe.recipe,
                                        ingredients: recipe.ingredients,
                                        desc: recipe.description,
                                        cookTime: recipe.cookTime,
                                        type: recipe.type ?? "",
                                        imageURL: downloadURL.absoluteString
                            )
                    }
                    self.delegate?.handleViewModelOutput(.setLoading(false))
                    self.delegate?.handleViewModelOutput(.successSave)
                } catch {
                    self.delegate?.handleViewModelOutput(.showError(error))
                    self.delegate?.handleViewModelOutput(.setLoading(false))
                }
            } catch {
                self.delegate?.handleViewModelOutput(.showError(error))
                self.delegate?.handleViewModelOutput(.setLoading(false))
            }
        }
    }
    
    
    func getRecipe(input: String) throws -> RecipeResponseModel? {
        if let data = self.separateJson(json: input) {
            if let responseModel = try? JSONDecoder().decode(RecipeResponseModel.self, from: data) {
                let recipe = RecipeResponseModel(foodName: responseModel.foodName, ingredients: responseModel.ingredients, recipe: responseModel.recipe, cookTime: responseModel.cookTime, description: responseModel.description, type: responseModel.type)
                return recipe
            } else {
                throw WFError.invalidResponse
            }
        } else{
            throw WFError.invalidResponse
        }
    }
    
    
    func separateJson(json: String) -> Data? {
        if let startIndex = json.range(of: "{"),
           let endIndex = json.range(of: "}", options: .backwards) {
            _ = json[startIndex.upperBound...endIndex.lowerBound]
            let jsonString = json
            return jsonString.data(using: .utf8)
        }
        return nil
    }
}

extension DiscoverFoodViewModelOutput {
    static func == (lhs: DiscoverFoodViewModelOutput, rhs: DiscoverFoodViewModelOutput) -> Bool {
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
