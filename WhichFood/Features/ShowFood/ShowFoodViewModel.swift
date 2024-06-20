//
//  ShowFoodViewModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 14.09.2023.
//

import Foundation
import FirebaseFirestore
import FirebaseFunctions
import FirebaseStorage


struct RecipeResponseModel: Decodable,Equatable {
    var foodName: String
    var ingredients : [String]
    var recipe: [String]
    var cookTime: String
    var description: String
    var type: String?
    var imageURL: String?
}

enum ShowFoodViewModelOutput: Equatable {
    case setLoading(Bool)
    case showRecipe(RecipeResponseModel)
    case showError(WFError)
    case saveRecipe
    case showImage(String)
    case successSave(Bool)
    case loadingImage(Bool)
}

protocol ShowFoodViewModelProtocol {
    var delegate: ShowFoodViewDelegate? { get set }
    func fetchFoodRecipe(foods: [Ingredient],category: [String])
    func saveRecipe()
}

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
    
    
    func generateString(foods:[Ingredient],category: [String]) -> String {
        let foodnames = foods.map { $0.name }
        let joinedCategoryStr = category.joined(separator: ", ")
        let joinedStr = foodnames.joined(separator: ", ")
        let currentLanguage = Bundle.main.preferredLocalizations.first ?? "Base"
        return "\(currentLanguage) \(LocaleKeys.ShowFood.prompt1.rawValue.locale()) \(joinedStr) \(LocaleKeys.ShowFood.prompt2.rawValue.locale()) \(joinedCategoryStr) \(LocaleKeys.ShowFood.prompt3.rawValue.locale())\(jsonString) \(LocaleKeys.ShowFood.prompt4.rawValue.locale()) \(LocaleKeys.ShowFood.prompt5.rawValue.locale())"
    }
    
    
    func saveRecipe(_ recipe: RecipeResponseModel?) {
        Task { [weak self] in
            guard let self = self else { return }
            self.delegate?.handleViewModelOutput(.setLoading(true))
            
            do{
                try await postImageToFirebase(imageURL: self.imageURL ?? "")
                
                let storageRef = Storage.storage().reference().child("foodImages/\(recipe!.foodName)")
                
                try await Task.sleep(nanoseconds: 3 * 1_000_000_000)
                
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
                    self.delegate?.handleViewModelOutput(.setLoading(false))
                    self.delegate?.handleViewModelOutput(.successSave(true))
                }
            } catch {
                self.delegate?.handleViewModelOutput(.showError(error as! WFError))
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
                self.delegate?.handleViewModelOutput(.loadingImage(false))
            } catch {
                self.delegate?.handleViewModelOutput(.showError(error as! WFError))
                self.delegate?.handleViewModelOutput(.loadingImage(false))
            }
        }
    }
    
    
    func postImageToFirebase(imageURL:String) async throws{
        guard let imageURL = URL(string:imageURL) else { return }
        do {
            self.imageURL = try await SavedRecipesManager.shared.uploadImageToFirebase(imageURL: imageURL, foodName: self.recipe?.foodName ?? "")
            print(imageURL)
        } catch {
            throw WFError.uploadPhotoError
        }
        
    }
    
    
    func increaseUsageApi() async throws{
        do{
            try await UserManager.shared.increaseApiUsage()
        } catch{
            self.delegate?.handleViewModelOutput(.showError(error as! WFError))
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
    

    @MainActor
    func fetchFoodRecipe(foods: [Ingredient], category: [String]) {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await increaseUsageApi()
                self.delegate?.handleViewModelOutput(.setLoading(true))
                self.delegate?.handleViewModelOutput(.loadingImage(true))
                let response = try await SavedRecipesManager.shared.postData(input: self.generateString(foods: foods, category: category))
                self.recipe = try self.getRecipe(input: response)
                self.delegate?.handleViewModelOutput(.showRecipe(self.recipe!))
                self.downloadImage()
                self.delegate?.handleViewModelOutput(.setLoading(false))
            } catch {
                throw WFError.invalidResponse
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
