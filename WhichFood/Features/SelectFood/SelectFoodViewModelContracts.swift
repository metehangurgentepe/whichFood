//
//  SelectFoodViewModelContracts.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 14.03.2024.
//

import Foundation
import UIKit

protocol SelectFoodViewDelegate: AnyObject {
    func onIngredientsUpdated()
    func onError(_ error: WFError)
    func buttonLoading(isLoading: Bool)
    func navigate()
}

protocol SelectFoodViewModelProtocol{
    var delegate: SelectFoodViewDelegate? {get set}
    
    func chooseIngredient(ingredient: Ingredient)
    func inSearchMode(_ searchController: UISearchController) -> Bool
    func updateSearchController(searchBarText: String?)
    
}
