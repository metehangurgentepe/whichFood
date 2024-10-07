//
//  DetailRecipeViewModelContracts.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 14.03.2024.
//

import Foundation

protocol DetailRecipeVCDelegate: AnyObject{
    func showDetail(_ recipe: Recipe)
}

protocol DetailRecipeViewModelProtocol {
    var delegate: DetailRecipeVCDelegate? { get set }
    func load()
}
