//
//  HomeViewModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 15.09.2023.
//

import Foundation
import FirebaseStorage
import UIKit

class HomeViewModel: HomeViewModelProtocol{
    weak var delegate: HomeViewModelDelegate?
    private(set) var recipes : [Recipe] = []
    private(set) var isEmptyRecipe: Bool = true
    
    @MainActor
    func getRecipes() {
        delegate?.handleViewModelOutput(.setLoading(true))
        
        Task{ [weak self] in
            guard let self = self else { return }
            do {
                self.recipes = try await SavedRecipesManager.shared.getAllRecipesByUser()
                if !self.recipes.isEmpty{
                    self.delegate?.handleViewModelOutput(.showRecipeList(recipes))
                    self.delegate?.handleViewModelOutput(.setLoading(false))
                } else {
                    self.delegate?.handleViewModelOutput(.emptyList)
                    self.delegate?.handleViewModelOutput(.setLoading(false))
                }
            } catch{
                self.delegate?.handleViewModelOutput(.showError(error as! WFError))
                self.delegate?.handleViewModelOutput(.setLoading(false))
            }
        }
    }
    
    func deleteRecipe(recipe: Recipe) {
        SavedRecipesManager.shared.deleteRecipeByUserID(id: recipe.id)
        Task{
            await self.getRecipes()
        }
    }
    
    
    func createText(recipe: Recipe) -> String {
        let name = recipe.name
        
        let instructions = recipe.recipe?.joined(separator: "\n")
        
        let ingredients = recipe.ingredients?.joined(separator: "\n")
        
        var text = "\(LocaleKeys.Recipe.name.rawValue.locale()): \(name)\n\n"
        if let instructions = instructions {
            text += "\(LocaleKeys.Recipe.name.rawValue.locale()): \n\(instructions)\n\n"
        }
        if let ingredients = ingredients {
            text += "\(LocaleKeys.Recipe.name.rawValue.locale()): \n\(ingredients)"
        }
        return text
    }
    
    
    func selectRecipe(at index: Int) {
        delegate?.navigate(to: .details(index))
    }
    
    
    func increaseApiUsage() async throws {
        do{
            try await UserManager.shared.increaseApiUsage()
            self.delegate?.handleViewModelOutput(.prepareRandomRecipe)
        } catch {
            self.delegate?.handleViewModelOutput(.showError(error as! WFError))
        }
    }
    
    
    func filter(word: String) {
        switch word {
        case Categories.homeCategoryList[0]: // "All"
            self.delegate?.handleViewModelOutput(.showRecipeList(self.recipes))

        case Categories.homeCategoryList[1]: // "Meaty" -> search for "meat"
            let recipe = self.recipes.filter{ $0.type?.lowercased() == "meat"}
            self.delegate?.handleViewModelOutput(.showRecipeList(recipe))

        case Categories.homeCategoryList[2]: // "Vegetarian" -> search for "vegetable"
            let recipe = self.recipes.filter{ $0.type?.lowercased() == "vegetable"}
            self.delegate?.handleViewModelOutput(.showRecipeList(recipe))

        case Categories.homeCategoryList[3]: // "Dessert" -> search for "dessert"
            let recipe = self.recipes.filter{ $0.type?.lowercased() == "dessert"}
            self.delegate?.handleViewModelOutput(.showRecipeList(recipe))
        default:
            break
        }
    }
}

extension RecipeListViewModelOutput {
    static func == (lhs: RecipeListViewModelOutput, rhs: RecipeListViewModelOutput) -> Bool {
        switch (lhs, rhs) {
        case (.setLoading(let a), .setLoading(let b)):
            return a == b
        case (.showRecipeList(let a), .showRecipeList(let b)):
            return a == b
        default:
            return false
        }
    }
}
