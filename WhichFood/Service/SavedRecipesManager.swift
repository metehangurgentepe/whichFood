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
import FirebaseStorage

class SavedRecipesManager{
    static let shared = SavedRecipesManager()
    private let recipesCollection = Firestore.firestore().collection("recipes")
    private let jsonDecoder = Utils.jsonDecoder
    private let baseURL = Constants.Api.baseURL.rawValue
    private let currentLanguage = Bundle.main.preferredLocalizations.first ?? "Base"
    
    private init(){}
    
    func getRecipe(id:String) async throws -> Recipe {
        try await recipesCollection.document(id).getDocument(as: Recipe.self)
    }
    
    func saveRecipe(name:String, recipe:[String], ingredients:[String], desc:String, cookTime: String, type: String, imageURL: String) async throws {
        let id = UUID()
        let createdTime = Timestamp()
        let userId = KeychainManager.get(account: "account")
        let currentLanguage = Bundle.main.preferredLocalizations.first ?? "Base"
        
        let recipeModel = Recipe(
            id: id.uuidString,
            name: name,
            recipe: recipe,
            ingredients: ingredients,
            description: desc,
            cookTime: cookTime,
            userId: String(decoding:userId ?? Data(), as:UTF8.self),
            createdAt: createdTime,
            type: type,
            imageUrl: imageURL,
            language: currentLanguage
        )
        
        do {
            let encodedRecipe = try Firestore.Encoder().encode(recipeModel)
            try await recipesCollection.document(id.uuidString).setData(encodedRecipe)
        } catch{
            throw error
        }
    }
    
    
    func deleteRecipeByUserID(id:String) {
        let field = ["userId": ""]
        recipesCollection.document(id).updateData(field)
    }
    
    
    func getAllRecipesByUser() async throws -> [Recipe] {
        do{
            let userId = KeychainManager.get(account: "account")
            let documentId = String(decoding:userId ?? Data(), as:UTF8.self)
            return try await recipesCollection
                .whereField("userId", isEqualTo: documentId)
                .getDocuments(as: Recipe.self)
        } catch {
            throw WFError.invalidResponse
        }
    }
    
    
    func getRecipes() async throws -> [Recipe] {
        do {
            let array = try await recipesCollection
                .limit(to: 20)
                .whereField("language", isEqualTo: currentLanguage)
                .getDocuments(as: Recipe.self)
                .compactMap { $0 }
            return array
        } catch {
            throw WFError.invalidEndpoint
        }
    }
    
    
    func searchRecipe(query:String) async throws -> [Recipe] {
        do{
            return try await recipesCollection
                .limit(to: 30)
                .whereField("language", isEqualTo: currentLanguage)
                .whereField("name", isGreaterThan: query)
                .whereField("name", isLessThan: query + "z")
                .getDocuments(as: Recipe.self)
                .compactMap { $0 }
        } catch {
            throw WFError.invalidResponse
        }
    }
    
    
    func saveImageToFirebase(image: UIImage, foodName: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            throw WFError.networkError
        }
        
        let imageName = UUID().uuidString
        
        let storage = Storage.storage()
        
        let storageRef = storage.reference().child("\(foodName)/\(imageName)")
        
        do {
            let metadata = storageRef.putData(imageData)
            let downloadURL = try await storageRef.downloadURL()
            return downloadURL.absoluteString
        } catch {
            throw WFError.uploadPhotoError
        }
    }
    
    
    func compressImage(imageURL: URL, compressionQuality: CGFloat) throws -> Data {
        guard let originalImage = UIImage(data: try Data(contentsOf: imageURL)) else {
            throw WFError.uploadPhotoError
        }
        return originalImage.jpegData(compressionQuality: compressionQuality) ?? Data()
    }
    
    
    func uploadImageToFirebase(imageURL: URL, foodName: String) async throws -> String {
        let compressedImageData = try compressImage(imageURL: imageURL, compressionQuality: 0.4)
        
        let storage = Storage.storage()
        
        let storageRef = storage.reference().child("foodImages/\(foodName)")
        
        storageRef.putData(compressedImageData)
        
        do {
            let downloadURL = try await storageRef.downloadURL()
            return downloadURL.absoluteString
        } catch {
            throw error
        }
    }
    
    
    func postData(input: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/openAIChatCompletion") else { throw WFError.invalidEndpoint }
        
        let parameters: [String: String] = [
            "message": input,
        ]
        
        return try await self.loadURLAndDecode(url: url, params: parameters)
    }
    
    
    func generateImage(input: String) async throws -> String {
        guard let url = URL(string:"\(baseURL)/generateImage") else {
            throw WFError.invalidEndpoint
        }
        
        let parameters: [String: String] = [
            "message": input,
        ]
        
        return try await self.loadURLAndDecode(url: url, params: parameters)
    }
    
    
    private func loadURLAndDecode<D: Decodable>(url: URL, method: String = "POST", params: [String: String]? = nil) async throws -> D {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        
        if let params = params {
            urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: params)
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw WFError.invalidResponse
        }
        
        do {
            jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
            return try jsonDecoder.decode(D.self, from: data)
        } catch {
            throw WFError.serializationError
        }
    }
    
    
}


extension Query {
    func getDocuments<T>(as type:T.Type) async throws -> [T] where T: Decodable {
        let snapshot = try await self.getDocuments()
        return try snapshot.documents.map { document in
            return try document.data(as: T.self)
        }
    }
}
