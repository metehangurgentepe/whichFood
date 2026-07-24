//
//  ImageToTextViewModelContracts.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 14.03.2024.
//

import Foundation

protocol ImageToTextViewModelDelegate: AnyObject{
    func handleViewModelOutput(_ output: ImageToTextViewModeOutput)
    func navigate(to navigationType: NavigationType)
}

enum ImageToTextViewModeOutput: Equatable {
    case setLoading(Bool)
    case showRecipe(RecipeResponseModel)
    case showError(Error)
    case saved
}

protocol ImageToTextViewModelProtocol {
    var delegate: ImageToTextViewModelDelegate? {get set}
}
