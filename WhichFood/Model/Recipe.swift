//
//  Recipe.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 15.09.2023.
//

import Foundation
import FirebaseFirestore

struct Recipe: Codable{
    var id: String
    var name: String
    var recipe: [String]
    var ingredients: [String]
    var description: String
    var cookTime: String
    var userId: String
    var createdAt: Timestamp
}
