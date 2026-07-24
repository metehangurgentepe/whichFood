//
//  SearchViewContracts.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 6.03.2024.
//

import Foundation

protocol SearchViewModelProtocol {
    var delegate: SearchViewModelDelegate? { get set }
    func load()
    func search(filter: String)
}

enum SearchViewModelOutput {
    case getRecipeBySearch([Recipe])
    case loadRecipes([Recipe])
    case setLoading(Bool)
    case error(WFError)
}

protocol SearchViewModelDelegate: AnyObject {
    func handleOutput(_ output: SearchViewModelOutput)
    func navigate(to navigationType: NavigationType)
}
