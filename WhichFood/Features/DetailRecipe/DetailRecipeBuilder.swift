//
//  DetailRecipeBuilder.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 2.11.2023.
//

import Foundation
final class DetailRecipeBuilder {
    static func make(with viewModel: DetailRecipeViewModelProtocol) -> DetailRecipeVC {
        let viewController = DetailRecipeVC() 
        viewController.viewModel = viewModel
        return viewController
    }
}
