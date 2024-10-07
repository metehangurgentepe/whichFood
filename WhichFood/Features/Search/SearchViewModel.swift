//
//  SearchViewModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 6.03.2024.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift
import FirebaseFirestore


class SearchViewModel: SearchViewModelProtocol{
    var delegate: SearchViewModelDelegate?
    
    func load() {
        Task{
            do{
                self.delegate?.handleOutput(.setLoading(true))
                let recipes = try await SavedRecipesManager.shared.getRecipes()
                self.delegate?.handleOutput(.loadRecipes(recipes))
                self.delegate?.handleOutput(.setLoading(false))
            } catch {
                self.delegate?.handleOutput(.error(WFError.apiError))
                self.delegate?.handleOutput(.setLoading(false))
            }
        }
    }
    
    
    func selectRecipe(at index: Int) {
        delegate?.navigate(to: .details(index))
    }
    
    
    func search(filter: String) {
        Task{
            do{
                let filteredRecipes = try await SavedRecipesManager.shared.searchRecipe(query: filter)
                self.delegate?.handleOutput(.getRecipeBySearch(filteredRecipes))
            } catch {
                self.delegate?.handleOutput(.error(WFError.invalidResponse))
            }
        }
    }
}
