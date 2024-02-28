//
//  ShowFoodViewModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 14.09.2023.
//

import Foundation
import FirebaseFirestore
import FirebaseFunctions


struct RecipeResponseModel: Decodable,Equatable {
    var foodName: String
    var ingredients : [String]
    var recipe: [String]
    var cookTime: String
    var description: String
}

enum ShowFoodViewModelOutput: Equatable {
    case setLoading(Bool)
    case showRecipe(RecipeResponseModel)
    case showError(Error)
    case saveRecipe
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
    private(set) var ingredients : [String] = []
    private(set) var recipe : [String] = []
    private(set) var cookTime : String = ""
    private(set) var foodName : String = ""
    private(set) var desc : String = ""
    
    
    func generateString(foods:[Ingredient],category: [String]) -> String {
        let foodnames = foods.map { $0.name }
        let joinedCategoryStr = category.joined(separator: ", ")
        let joinedStr = foodnames.joined(separator: ", ")
        let currentLanguage = Bundle.main.preferredLocalizations.first ?? "Base"
        print(currentLanguage)
        return "\(currentLanguage) \(LocaleKeys.ShowFood.prompt1.rawValue.locale()) \(joinedStr) \(LocaleKeys.ShowFood.prompt2.rawValue.locale()) \(joinedCategoryStr) \(LocaleKeys.ShowFood.prompt3.rawValue.locale())\(jsonString) \(LocaleKeys.ShowFood.prompt4.rawValue.locale()) "
    }
    
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
          "description": ""
        }
        """
    
    func saveRecipe(_ recipe: RecipeResponseModel?) {
        Task { [weak self] in
            self?.delegate?.handleViewModelOutput(.setLoading(true))
            if let recipe = recipe {
                try await SavedRecipesManager
                    .shared
                    .saveRecipe(name: recipe.foodName,
                                recipe: recipe.recipe,
                                ingredients: recipe.ingredients,
                                desc: recipe.description,
                                cookTime: recipe.cookTime)
                self?.delegate?.handleViewModelOutput(.setLoading(false))
            } else {
                let error = NSError()
                self?.delegate?.handleViewModelOutput(.showError(error))
            }
        }
    }
    
    func increaseUsageApi() async throws{
        do{
            try await UserManager.shared.increaseApiUsage()
        } catch{
            self.delegate?.handleViewModelOutput(.showError(error))
        }
    }
    
    func separateJson(json: String) -> Data? {
        if let startIndex = json.range(of: "{"),
           let endIndex = json.range(of: "}", options: .backwards) {
            let jsonSubstring = json[startIndex.upperBound...endIndex.lowerBound]
            var jsonString = json
            return jsonString.data(using: .utf8)
        }
        return nil
    }

    @MainActor
    func fetchFoodRecipe(foods: [Ingredient], category: [String]) {
        Task { [weak self] in
            self?.delegate?.handleViewModelOutput(.setLoading(true))
            SavedRecipesManager.shared.postData(input: self?.generateString(foods: foods, category: category) ?? "Give recipe") { response, error in
                do {
                    if let error = error {
                        throw error
                    }
                    guard let response = response else {
                        throw NSError(domain: "YourDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Response is nil"])
                    }
                    
                    if let data = self?.separateJson(json: response) {
                        let responseModel = try JSONDecoder().decode(RecipeResponseModel.self, from: data)
                        let recipe = RecipeResponseModel(foodName: responseModel.foodName, ingredients: responseModel.ingredients, recipe: responseModel.recipe, cookTime: responseModel.cookTime, description: responseModel.description)
                        DispatchQueue.main.async{
                            self?.delegate?.handleViewModelOutput(.showRecipe(recipe))
                        }
                    } else {
                        let error = NSError(domain: "YourDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "JSON decoding failed"])
                        self?.delegate?.handleViewModelOutput(.showError(error))
                    }
                } catch {
                    DispatchQueue.main.async{
                        self?.delegate?.handleViewModelOutput(.showError(error))
                    }
                }
                DispatchQueue.main.async{
                    self?.delegate?.handleViewModelOutput(.setLoading(false))
                }
            }
        }
    }
    
//    func postData(foods: [Ingredient], category: [String]) async {
//        do {
//             Task { [weak self] in
//                self?.delegate?.handleViewModelOutput(.setLoading(true))
//                do {
//                   try await SavedRecipesManager.shared.fetchRecipe(message: self?.generateString(foods: foods, category: category) ?? "Give recipe") { response, error in
//                        if let error = error {
//                            self?.delegate?.handleViewModelOutput(.showError(error))
//                        }
//                        
//                        if let data = self?.separateJson(json: response?.text ?? "nil") {
//                            let responseModel = try JSONDecoder().decode(RecipeResponseModel.self, from: data)
//                            let recipe = RecipeResponseModel(foodName: responseModel.foodName, ingredients: responseModel.ingredients, recipe: responseModel.recipe, cookTime: responseModel.cookTime, description: responseModel.description)
//                            self?.delegate?.handleViewModelOutput(.showRecipe(recipe))
//                        } else {
////                            self?.delegate?.handleViewModelOutput(.showError(error ?? nil))
//                        }
//                    }
//                } catch {
//                    self?.delegate?.handleViewModelOutput(.showError(error))
//                }
//                
//                self?.delegate?.handleViewModelOutput(.setLoading(false))
//            }
//        } catch {
//            self.delegate?.handleViewModelOutput(.showError(error))
//        }
//    }

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
