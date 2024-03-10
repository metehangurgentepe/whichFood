//
//  Foods.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 12.09.2023.
//

import Foundation

struct Ingredient: Equatable {
    var name: String
    var category: CategoryModel
    var isSelected: Bool
}

enum CategoryModel: String {
    case vegetable
    case meat
    case dairyProducts
    case grain
    
}


