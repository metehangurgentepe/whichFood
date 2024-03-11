//
//  FavoritesViewModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 6.03.2024.
//

import Foundation

class FavoriteViewModel: FavoriteViewModelProtocol {
    var delegate: FavoriteViewModelDelegate?
    
    var recipes: [Recipe] = []
    
    func load() {
        PersistenceManager.retrieveFavorites {[weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let favorites):
                self.recipes = favorites
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
