//
//  PersistenceManager.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 6.03.2024.
//

import Foundation

enum PersistenceActionType {
    case add, remove
}


enum PersistenceManager {
    static private let defaults = UserDefaults.standard
    
    enum Keys {
        static let favorites = "favorites"
    }
    
    static func isSaved(recipe: RecipeResponseModel, completion: @escaping (Result<Bool,WFError>) -> Void) {
        retrieveFavorites { result in
            switch result {
            case .success(let favorites):
                guard !favorites.contains(recipe) else {
                    completion(.success(true))
                    return
                }
                completion(.success(false))
            case .failure(let failure):
                completion(.failure(.serializationError))
            }
        }
    }
    
    
    static func updateWith(favorite: RecipeResponseModel, actionType: PersistenceActionType, completion: @escaping (WFError?) -> Void) {
        retrieveFavorites { result in
            switch result {
            case .success(var favorites):
                
                switch actionType {
                case .add:
                    guard !favorites.contains(favorite) else {
                        completion(.unableToFavorite)
                        return
                    }
                    
                    favorites.append(favorite)
                case .remove:
                    favorites.removeAll { $0.recipe == favorite.recipe }
                }
                
               completion(save(favorites: favorites))
                
                
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    
    static func retrieveFavorites(completion: @escaping (Result<[RecipeResponseModel],WFError>) -> Void) {
        guard let favoritesData = defaults.object(forKey: Keys.favorites) as? Data else {
            completion(.success([]))
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let favorites = try decoder.decode([RecipeResponseModel].self, from: favoritesData)
            completion(.success(favorites))
        } catch {
            completion(.failure(.unableToFavorite))
        }
    }
    
    
    static func save(favorites: [RecipeResponseModel]) -> WFError? {
        do {
            let encoder = JSONEncoder()
            let encodedFavorites = try encoder.encode(favorites)
            defaults.setValue(encodedFavorites, forKey: Keys.favorites)
            return nil
        } catch {
            return .unableToFavorite
        }
    }
}
