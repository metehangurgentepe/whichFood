//
//  SearchViewModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 6.03.2024.
//

import Foundation


class SearchViewModel: SearchViewModelProtocol{
    var delegate: SearchViewModelDelegate?
    
    func load() {
        Task{
            do{
                let recipes = try await SavedRecipesManager.shared.getRecipes()
                self.delegate?.handleOutput(.loadRecipes(recipes))
            } catch {
                self.delegate?.handleOutput(.error(WFError.apiError))
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
