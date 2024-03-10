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
    case showError(Error)
    case emptyList
}

protocol HomeViewModelProtocol {
    var delegate: HomeViewModelDelegate? {get set}
    func getRecipes()
    func delete(id: String,index: Int)
    func selectRecipe(at index: Int)
}

class HomeViewModel: HomeViewModelProtocol{
    weak var delegate: HomeViewModelDelegate?
    private(set) var recipes : [Recipe] = []
    private(set) var isEmptyRecipe: Bool = true
    
    @MainActor
    func getRecipes() {
        delegate?.handleViewModelOutput(.setLoading(true))
        
        Task{ [weak self] in
            do {
                self?.recipes = try await SavedRecipesManager.shared.getAllRecipes()
                if let recipes = self?.recipes, !recipes.isEmpty{
                    self?.delegate?.handleViewModelOutput(.showRecipeList(recipes))
                    self?.delegate?.handleViewModelOutput(.setLoading(false))
                } else {
                    self?.delegate?.handleViewModelOutput(.emptyList)
                    self?.delegate?.handleViewModelOutput(.setLoading(false))
                }
            } catch{
                self?.delegate?.handleViewModelOutput(.showError(error))
                self?.delegate?.handleViewModelOutput(.setLoading(false))
            }
        }
    }
    
    func delete(id: String,index: Int) {
        SavedRecipesManager.shared.deleteRecipe(id: id)
        self.delegate?.delete(index: index)
    }
    
    func selectRecipe(at index: Int) {
        delegate?.navigate(to: .details(index))
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
