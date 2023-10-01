//
//  SavedRecipesManager.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 15.09.2023.
//

import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore

class SavedRecipesManager{
    static let shared = SavedRecipesManager()
    private let recipesCollection = Firestore.firestore().collection("recipes")
    
    private init(){}
    
    func getRecipe(id:String) async throws -> Recipe {
        try await recipesCollection.document(id).getDocument(as: Recipe.self)
    }
    
    func saveRecipe(name:String,recipe:[String],ingredients:[String],desc:String,cookTime: String) async throws {
        let id = UUID()
        let createdTime = Timestamp()
        let userId = await UIDevice.current.identifierForVendor?.uuidString
        let recipeModel = Recipe(id: id.uuidString, name: name, recipe: recipe, ingredients: ingredients, description: desc, cookTime:cookTime, userId:userId ?? "", createdAt: createdTime)
        do {
            let encodedRecipe = try Firestore.Encoder().encode(recipeModel)
            try await recipesCollection.document(id.uuidString).setData(encodedRecipe)
        } catch{
            throw error
        }
    }
    
    func deleteRecipe(id:String) {
        recipesCollection.document(id).delete()
    }
    
    func getAllRecipes() async throws -> [Recipe] {
        let deviceId = await UIDevice.current.identifierForVendor?.uuidString
        return try await recipesCollection
            .whereField("userId", isEqualTo: deviceId!)
            .getDocuments(as: Recipe.self)
    }
}


extension Query {
    func getDocuments<T>(as type:T.Type) async throws -> [T] where T: Decodable {
        let snapshot = try await self.getDocuments()
        return try snapshot.documents.map { document in
            try document.data(as: T.self)
        }
    }
}
