//
//  HomeViewModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 15.09.2023.
//

import Foundation
import FirebaseStorage
import UIKit


enum RecipeListViewModelOutput: Equatable {
    case setLoading(Bool)
    case showRecipeList([Recipe])
    case showError(WFError)
    case emptyList
}

protocol HomeViewModelProtocol {
    var delegate: HomeViewModelDelegate? {get set}
    func getRecipes()
    func selectRecipe(at index: Int)
    func deleteRecipe(recipe: Recipe)
}

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
    
    
    func selectRecipe(at index: Int) {
        delegate?.navigate(to: .details(index))
    }
    
    
    func increaseApiUsage() async throws {
        do{
            let vc = await DiscoverFoodVC()
            try await UserManager.shared.increaseApiUsage()
            self.delegate?.navigate(to: .goToVC(vc))
        } catch {
            self.delegate?.handleViewModelOutput(.showError(error as! WFError))
        }
    }
    
    
    func filter(word: String) {
        switch word {
        case Categories.homeCategoryList[0]:
            self.delegate?.handleViewModelOutput(.showRecipeList(self.recipes))
            
        case Categories.homeCategoryList[1]:
            let recipe = self.recipes.filter{ $0.type?.lowercased() == Categories.homeCategoryList[1].lowercased()}
            self.delegate?.handleViewModelOutput(.showRecipeList(recipe))
            
        case Categories.homeCategoryList[2]:
            let recipe = self.recipes.filter{ $0.type?.lowercased() == Categories.homeCategoryList[2].lowercased()}
            self.delegate?.handleViewModelOutput(.showRecipeList(recipe))
            
        case Categories.homeCategoryList[3]:
            let recipe = self.recipes.filter{ $0.type?.lowercased() == Categories.homeCategoryList[3].lowercased()}
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
