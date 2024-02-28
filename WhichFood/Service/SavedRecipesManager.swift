//
//  SavedRecipesManager.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 15.09.2023.
//

import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore
import FirebaseFunctions
import Alamofire

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
        let userId = KeychainManager.get(account: "account")
        let recipeModel = Recipe(
            id: id.uuidString,
            name: name,
            recipe: recipe,
            ingredients: ingredients,
            description: desc,
            cookTime: cookTime,
            userId: String(decoding:userId ?? Data(), as:UTF8.self),
            createdAt: createdTime
        )
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
        let userId = KeychainManager.get(account: "account")
        let documentId = String(decoding:userId ?? Data(), as:UTF8.self)
        return try await recipesCollection
            .whereField("userId", isEqualTo: documentId)
            .getDocuments(as: Recipe.self)
    }
    
    func fetchRecipe(message: String, completion: @escaping (Result<String, Error>) -> Void) {
        let functions = Functions.functions()

        // Replace the name of your function
        let openAIChatCompletion = functions.httpsCallable("openAIChatCompletion")

        let data: [String: Any] = ["message": message]

        openAIChatCompletion.call(data) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = result?.data as? [String: Any],
                  let responseString = data["your_expected_key"] as? String else {
                completion(.failure(NSError(domain: "YourDomain", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unexpected response format"])))
                return
            }

            completion(.success(responseString))
        }
    }
    
    func postData(input: String, completion: @escaping (String?, Error?) -> Void) {
        let url = URL(string: "https://europe-west3-whichfood-983f1.cloudfunctions.net/openAIChatCompletion")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        let parameters: [String: Any] = [
            "message": input,
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, let response = response as? HTTPURLResponse, error == nil else {
                completion(nil, error)
                return
            }

            guard (200 ... 299) ~= response.statusCode else {
                completion(nil, NSError(domain: "HTTPError", code: response.statusCode, userInfo: nil))
                return
            }

            do {
                let responseObject = try JSONDecoder().decode(String.self, from: data)
                print(responseObject)
                completion(responseObject, nil)
            } catch {
                completion(nil, error)
            }
        }

        task.resume()
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
