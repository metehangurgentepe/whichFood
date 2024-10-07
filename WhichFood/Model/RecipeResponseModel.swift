//
//  RecipeResponseModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 14.03.2024.
//

import Foundation

struct RecipeResponseModel: Decodable,Equatable {
    var foodName: String
    var ingredients : [String]
    var recipe: [String]
    var cookTime: String
    var description: String
    var type: String?
    var imageURL: String?
}
