//
//  DetailRecipeViewModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 22.09.2023.
//

import Foundation
import UIKit

protocol DetailRecipeViewModelProtocol {
    var delegate: DetailRecipeVCDelegate? { get set }
    func load()
}

class DetailRecipeViewModel: DetailRecipeViewModelProtocol {
    weak var delegate: DetailRecipeVCDelegate?
    private let recipe: Recipe
    
    init(recipe: Recipe) {
        self.recipe = recipe
    }
    
    func load() {
        delegate?.showDetail(recipe)
    }
}
