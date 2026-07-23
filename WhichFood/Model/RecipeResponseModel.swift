//
//  RecipeResponseModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 14.03.2024.
//

import Foundation

struct RecipeResponseModel: Decodable, Equatable, Encodable {
    var foodName: String
    var ingredients: [String]
    var recipe: [String]
    var cookTime: String
    var prepTime: String?
    var totalTime: String?
    var difficulty: String?
    var servings: String?
    var description: String
    var type: String?
    var cuisine: String?
    var allergens: [String]?
    var tags: [String]?
    var cal: CalorieInfo?
    var nutritionalInfo: NutritionalInfo?
    var tips: [String]?
    var imageURL: String?
    
    static func fromRecipe(_ recipe: Recipe) -> RecipeResponseModel {
            return RecipeResponseModel(
                foodName: recipe.name,
                ingredients: recipe.ingredients ?? [],
                recipe: recipe.recipe ?? [],
                cookTime: recipe.cookTime ?? Date().description,
                prepTime: recipe.prepTime,
                totalTime: recipe.totalTime,
                difficulty: recipe.difficulty,
                servings: recipe.servings,
                description: recipe.description ?? "",
                type: recipe.type,
                cuisine: recipe.cuisine,
                allergens: recipe.allergens,
                tags: recipe.tags,
                cal: recipe.cal,
                nutritionalInfo: recipe.nutritionalInfo,  // Map from nutritionalInfo to nutrition
                tips: recipe.tips,
                imageURL: recipe.imageUrl
            )
        }
}

struct CalorieInfo: Codable, Equatable, Hashable {
    var carbs: String
    var fat: String
    var protein: String
    var totalCalories: String?
    
    // Hashable için hash değeri hesaplama
    func hash(into hasher: inout Hasher) {
        hasher.combine(carbs)
        hasher.combine(fat)
        hasher.combine(protein)
        hasher.combine(totalCalories)
    }
}

struct NutritionalInfo: Codable, Equatable, Hashable {
    var sugar: String?
    var fiber: String?
    var sodium: String?
    var cholesterol: String?
    
    // Hashable için hash değeri hesaplama
    func hash(into hasher: inout Hasher) {
        hasher.combine(sugar)
        hasher.combine(fiber)
        hasher.combine(sodium)
        hasher.combine(cholesterol)
    }
}
