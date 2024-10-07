//
//  ShowFoodViewModelContracts.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 14.03.2024.
//

import Foundation

enum ShowFoodViewModelOutput: Equatable {
    case setLoading(Bool)
    case showRecipe(RecipeResponseModel)
    case showError(WFError)
    case saveRecipe
    case showImage(String)
    case successSave(Bool)
    case loadingImage(Bool)
}

protocol ShowFoodViewModelProtocol {
    var delegate: ShowFoodViewDelegate? { get set }
    func fetchFoodRecipe(foods: [Ingredient],category: [String])
    func saveRecipe()
}

protocol ShowFoodViewDelegate: AnyObject {
    func handleViewModelOutput(_ output: ShowFoodViewModelOutput)
}
