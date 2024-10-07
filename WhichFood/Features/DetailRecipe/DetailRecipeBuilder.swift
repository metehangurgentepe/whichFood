//
//  DetailRecipeBuilder.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 2.11.2023.
//

import Foundation
import UIKit

final class DetailRecipeBuilder {
    static func make(with viewModel: DetailRecipeViewModelProtocol) -> DetailRecipeVC {
        let viewController = DetailRecipeVC(collectionViewLayout: UICollectionViewFlowLayout())
        viewController.viewModel = viewModel
        return viewController
    }
}
