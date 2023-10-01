//
//  ShowFoodViewModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 14.09.2023.
//

import Foundation
import OpenAISwift

protocol ShowFoodViewDelegate: AnyObject {
    func didFinish()
    func didFail(error: Error)
}

class ShowFoodViewModel {
    var selectedFoods = [Ingredient]()
    
    weak var delegate: ShowFoodViewDelegate?
    private(set) var isLoading: Bool = false // Add isLoading property
    
    //private(set) var recipe : String = ""
    private(set) var ingredients : [String] = []
    private(set) var recipe : [String] = []
    private(set) var cookTime : String = ""
    private(set) var foodName : String = ""
    private(set) var desc : String = ""
    
    
    func generateString(foods:[Ingredient],category: [String]) -> String {
        let foodnames = foods.map { $0.name }
        let joinedCategoryStr = category.joined(separator: ", ")
        let joinedStr = foodnames.joined(separator: ", ")
        print(joinedStr)
        return "\(joinedStr) malzemeleri ile bir yemek tarifi öneririr misin? \(joinedCategoryStr) yemekler bu özellikleri içersin. \(jsonString) halinde json olarak ver. sadece json ver. önüne arkasına hiç bir şey yazma"
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

    
    func saveRecipe() async throws{
        isLoading = true
        try await SavedRecipesManager
            .shared
            .saveRecipe(name: foodName, recipe: recipe, ingredients: ingredients, desc: desc, cookTime: cookTime)
        isLoading = false
    }
    
    @MainActor
    func fetchFoodRecipe(foods: [Ingredient],category: [String]) {
        isLoading = true // Set isLoading to true when the fetch operation begins
        Task { [weak self] in
            APICaller.shared.getResponse(input: generateString(foods: foods, category: category)) { result in
                print(category)
                do {
                    switch result {
                    case .success(let output):
                        if let data = self?.seperateJson(json: output).data(using: .utf8) {
                            let responseModel = try JSONDecoder().decode(ResponseModel.self, from: data)
                            self?.foodName = responseModel.foodName
                            self?.cookTime = responseModel.cookTime
                            self?.desc = responseModel.description
                            self?.ingredients = responseModel.ingredients
                            self?.recipe = responseModel.recipe
                            self?.isLoading = false // Set isLoading to false when the fetch operation is complete
                            self?.delegate?.didFinish()
                        } else {
                            self?.desc = "hata"
                            self?.delegate?.didFinish()
                        }
                    case .failure(let error):
                        self?.isLoading = false // Set isLoading to false in case of an error
                        self?.delegate?.didFail(error: error)
                    }
                } catch {
                    self?.isLoading = false // Set isLoading to false in case of a decoding error
                    self?.delegate?.didFail(error: error)
                }
            }
        }
    }
    
    func seperateJson(json:String)-> String {
        if let startIndex = json.range(of: "{"),
           let endIndex = json.range(of: "}", options: .backwards) {
            let jsonSubstring = json[startIndex.upperBound...endIndex.lowerBound]
            var jsonString = json
            return jsonString
        }
        return json
    }
}

struct ResponseModel: Decodable {
    var foodName: String
    var ingredients : [String]
    var recipe: [String]
    var cookTime: String
    var description: String
}
