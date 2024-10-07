//
//  Recipe.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 15.09.2023.
//

import Foundation
import FirebaseFirestore

struct Recipe: Codable, Equatable, Hashable{
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
            keywords: [String] = []
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
        }
}
