//
//  Categories.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 8.03.2024.
//

import Foundation

enum Categories {
    static let easy = LocaleKeys.FoodCategory.easy.rawValue.locale()
    static let mid = LocaleKeys.FoodCategory.mid.rawValue.locale()
    static let hard = LocaleKeys.FoodCategory.hard.rawValue.locale()
    static let healthy = LocaleKeys.FoodCategory.healthy.rawValue.locale()
    static let enjoy = LocaleKeys.FoodCategory.enjoy.rawValue.locale()
    static let hearty = LocaleKeys.FoodCategory.hearty.rawValue.locale()
    static let vegan = LocaleKeys.FoodCategory.vegan.rawValue.locale()
    static let dessert = LocaleKeys.FoodCategory.dessert.rawValue.locale()
    static let vegetarian = LocaleKeys.FoodCategory.vegetarian.rawValue.locale()
    static let breakfast = LocaleKeys.FoodCategory.breakfast.rawValue.locale()
    static let lunch = LocaleKeys.FoodCategory.lunch.rawValue.locale()
    static let dinner = LocaleKeys.FoodCategory.dinner.rawValue.locale()
    static let meaty = LocaleKeys.Home.meaty.rawValue.locale()
    static let all = LocaleKeys.Home.all.rawValue.locale()
    
    static let categoriesList: [String] = [
            easy, mid, hard, healthy, enjoy, hearty, vegan, dessert, vegetarian, breakfast, lunch, dinner
    ]
    
    static let homeCategoryList : [String] = [ all, meaty, vegetarian, dessert ]
}
