//
//  Recipe.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 15.09.2023.
//

import Foundation
import FirebaseFirestore


struct Recipe: Codable, Equatable, Hashable {
    var id: String
    var name: String
    var recipe: [String]?
    var ingredients: [String]?
    var description: String?
    var cookTime: String?
    var userId: String
    var createdAt: Timestamp
    var type: String?
    var imageUrl: String?
    var language: String?
    var keywords: [String]?
    
    // Yeni eklenen alanlar
    var prepTime: String?
    var totalTime: String?
    var difficulty: String?
    var servings: String?
    var cuisine: String?
    var tags: [String]?
    var cal: CalorieInfo?
    var nutritionalInfo: NutritionalInfo?
    var allergens: [String]?
    var tips: [String]?
    
    init(
        id: String,
        name: String,
        recipe: [String],
        ingredients: [String],
        description: String,
        cookTime: String,
        userId: String,
        createdAt: Timestamp,
        type: String? = nil,
        imageUrl: String? = nil,
        language: String? = nil,
        keywords: [String] = [],
        prepTime: String? = nil,
        totalTime: String? = nil,
        difficulty: String? = nil,
        servings: String? = nil,
        cuisine: String? = nil,
        tags: [String]? = nil,
        cal: CalorieInfo? = nil,
        nutritionalInfo: NutritionalInfo? = nil,
        allergens: [String]? = nil,
        tips: [String]? = nil
    ) {
        self.id = id
        self.name = name
        self.recipe = recipe
        self.ingredients = ingredients
        self.description = description
        self.cookTime = cookTime
        self.userId = userId
        self.createdAt = createdAt
        self.type = type
        self.imageUrl = imageUrl
        self.language = language
        self.keywords = keywords
        self.prepTime = prepTime
        self.totalTime = totalTime
        self.difficulty = difficulty
        self.servings = servings
        self.cuisine = cuisine
        self.tags = tags
        self.cal = cal
        self.nutritionalInfo = nutritionalInfo
        self.allergens = allergens
        self.tips = tips
    }
    
    // Equatable gereksinimi (otomatik implementasyon yeterli, ancak performans için eklenebilir)
    static func == (lhs: Recipe, rhs: Recipe) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Hashable için hash değeri hesaplama (basitlik için sadece id kullandım)
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

