//
//  FavoriteViewModelContracts.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 6.03.2024.
//

import Foundation

protocol FavoriteViewModelProtocol {
    var delegate: FavoriteViewModelDelegate? { get set }
    func load()
}

enum FavoriteViewModelOutput{
    case favoriteList([Recipe])
    case error(WFError)
    case selectMovie(Int)
    case showEmptyView
}

protocol FavoriteViewModelDelegate: AnyObject {
    func handleOutput(_ output: FavoriteViewModelOutput)
    func navigate(to navigationType: NavigationType)
}

