//
//  DiscoverFoodViewModelContracts.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 14.03.2024.
//

import Foundation

protocol DiscoverFoodViewDelegate: AnyObject {
    func handleViewModelOutput(_ output: DiscoverFoodViewModelOutput)
}

enum DiscoverFoodViewModelOutput: Equatable {
    case setLoading(Bool)
    case showRecipe(RecipeResponseModel)
    case showError(Error)
    case saveRecipe
    case showImage(String)
    case loadingPhoto(Bool)
    case successSave
}

protocol DiscoverFoodViewModelProtocol {
    var delegate: DiscoverFoodViewDelegate? { get set }
    func fetchFoodRecipe(foods: [Ingredient],category: [String])
    func saveRecipe()
}
