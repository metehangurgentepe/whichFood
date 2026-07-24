//
//  FavoritesViewModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 6.03.2024.
//

import Foundation
import FirebaseFirestore

class FavoriteViewModel: FavoriteViewModelProtocol {
    var delegate: FavoriteViewModelDelegate?
    
    var recipes: [Recipe] = []
    
    func load() {
        PersistenceManager.retrieveFavorites {[weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let favorites):
                self.recipes = favorites.map({$0.toRecipe()})
                self.delegate?.handleOutput(.favoriteList(recipes))
                if recipes.isEmpty{
                    self.delegate?.handleOutput(.showEmptyView)
                }
            case .failure(let error):
                self.delegate?.handleOutput(.error(error))
            }
        }
    }
    
    
    func selectRecipe(id:Int) {
        self.delegate?.handleOutput(.selectMovie(id))
    }
}

extension RecipeResponseModel {
    func toRecipe() -> Recipe {
        return Recipe(
            id: UUID().uuidString,
            name: self.foodName,
            recipe: self.recipe,
            ingredients: self.ingredients,
            description: self.description,
            cookTime: self.cookTime,
            userId: "",
            createdAt: Timestamp(date: Date()),
            type: self.type,
            imageUrl: self.imageURL,
            language: Bundle.main.preferredLocalizations.first,
            keywords: []
        )
    }
}
