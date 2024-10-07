//
//  DetailRecipeViewModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 22.09.2023.
//

import Foundation
import UIKit


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
