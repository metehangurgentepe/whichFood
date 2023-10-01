//
//  Foods.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 12.09.2023.
//

import Foundation

struct Ingredient {
    var name: String
    var category: CategoryModel
    var isSelected: Bool
    
    init(name: String, category: CategoryModel, isSelected: Bool) {
            self.name = name
            self.category = category
            self.isSelected = isSelected
    }
}

enum CategoryModel: String {
    case vegetable
    case meat
    case dairyProducts
    case grain
    
}


