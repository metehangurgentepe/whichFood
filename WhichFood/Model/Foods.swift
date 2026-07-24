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
    
    static func == (lhs: Ingredient, rhs: Ingredient) -> Bool {
        return lhs.name == rhs.name &&
               lhs.category == rhs.category &&
               lhs.isSelected == rhs.isSelected
    }
}


enum CategoryModel: String {
    case vegetable
    case meat
    case dairy
    case grain
    case fruit
    case seafood
    case herb
    case nut
    
    var localizedValue: String {
        switch self {
        case .vegetable:
            return LocaleKeys.SelectFood.vegetable.rawValue.locale()
        case .meat:
            return LocaleKeys.SelectFood.meat.rawValue.locale()
        case .dairy:
            return LocaleKeys.SelectFood.dairy.rawValue.locale()
        case .grain:
            return LocaleKeys.SelectFood.grain.rawValue.locale()
        case .fruit:
            return LocaleKeys.SelectFood.fruit.rawValue.locale()
        case .seafood:
            return LocaleKeys.SelectFood.seafood.rawValue.locale()
        case .herb:
            return LocaleKeys.SelectFood.herb.rawValue.locale()
        case .nut:
            return LocaleKeys.SelectFood.nut.rawValue.locale()
        }
    }
}



