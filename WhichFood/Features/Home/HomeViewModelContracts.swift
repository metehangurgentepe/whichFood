//
//  HomeViewModelContracts.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 14.03.2024.
//

import Foundation
import UIKit

protocol HomeViewModelDelegate: AnyObject{
    func handleViewModelOutput(_ output: RecipeListViewModelOutput)
    func navigate(to navigationType: NavigationType)
}

enum NavigationType {
    case details(Int)
    case goToVC(UIViewController)
    case present(UIViewController)
}

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
