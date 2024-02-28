//
//  ImageToTextViewModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 5.12.2023.
//

import Foundation
import UIKit
import FirebaseStorage


enum ImageToTextViewModeOutput: Equatable {
    case setLoading(Bool)
    case showRecipe(RecipeResponseModel)
    case showError(Error)
    case saved
}

protocol ImageToTextViewModelProtocol {
    var delegate: ImageToTextViewModelDelegate? {get set}
}

class ImageToTextViewModel: ImageToTextViewModelProtocol{
    var delegate: ImageToTextViewModelDelegate?
    private (set) var recipeText: String?
    
    let jsonString = """
        {
          "foodName": "",
          "ingredients": [
            "",
          ],
          "recipe": [
            ""
          ],
          "cookTime": "",
          "description": ""
        }
        """
    
    func uploadRecipePhoto(image: UIImage) async {
        delegate?.handleViewModelOutput(.setLoading(true))
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            return
        }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        // Create a reference to the file you want to upload
        let recipePhotoRef = storageRef.child("recipe_photos").child(UUID().uuidString + ".jpg")
        
        // Upload the file to Firebase Storage
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        var getUrl = ""
        
        recipePhotoRef.putData(imageData, metadata: metadata) { (metadata, error) in
            if let error = error {
                self.delegate?.handleViewModelOutput(.showError(error))
                print("Error uploading image data: \(error.localizedDescription)")
            } else {
                // Successfully uploaded, now get the download URL
                recipePhotoRef.downloadURL { (url, error) in
                    if let downloadURL = url {
                        print("url's are \(url)")
                        getUrl = url?.absoluteString ?? ""
                        Task{
                            await self.getRecipeText(imageUrl: url?.absoluteString ?? "")
                        }
                        print("Recipe photo download URL: \(downloadURL.absoluteString)")
                    } else {
                        if let error = error {
                            print("Error getting download URL: \(error.localizedDescription)")
                            self.delegate?.handleViewModelOutput(.showError(error))
                            // Optionally show an error to the user or handle it appropriately
                        }
                    }
                }
            }
        }
    }
    
    func getRecipeText(imageUrl: String) async {
        delegate?.handleViewModelOutput(.setLoading(true))
        do {
            let response = try await ImageToTextManager.shared.postImage(url: imageUrl)
            print(response)
            await changeText(text: response)
        } catch {
            DispatchQueue.main.async{
                self.delegate?.handleViewModelOutput(.showError(error))
                self.delegate?.handleViewModelOutput(.setLoading(false))
            }
        }
    }
    
    func changeText(text: TextModel) async {
        delegate?.handleViewModelOutput(.setLoading(true))
        DispatchQueue.main.async{
            let recipe = text.TextDetections.map { text in
                return text.DetectedText
            }
            
            let input = "Convert this text into a proper recipe. Do not change the language. \(recipe) export this in \(self.jsonString) "
            
            SavedRecipesManager.shared.postData(input: input) { [weak self] text, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.delegate?.handleViewModelOutput(.showError(error))
                } else if let recipeText = text {
                    do {
                        if let data = self.separateJson(json: recipeText) {
                            let responseModel = try JSONDecoder().decode(RecipeResponseModel.self, from: data)
                            let recipe = RecipeResponseModel(foodName: responseModel.foodName, ingredients: responseModel.ingredients, recipe: responseModel.recipe, cookTime: responseModel.cookTime, description: responseModel.description)
                            self.delegate?.handleViewModelOutput(.showRecipe(recipe))
                            self.delegate?.handleViewModelOutput(.setLoading(false))
                        } else {
                            let error = NSError()
                            self.delegate?.handleViewModelOutput(.showError(error))
                        }
                    } catch {
                        self.delegate?.handleViewModelOutput(.showError(error))
                        self.delegate?.handleViewModelOutput(.setLoading(false))
                    }
                }
            }
        }
    }
    
    func saveRecipe(recipe: RecipeResponseModel?) async{
        if let recipe = recipe{
            do{
                try await SavedRecipesManager.shared.saveRecipe(
                    name: recipe.foodName,
                    recipe: recipe.recipe,
                    ingredients: recipe.ingredients,
                    desc: recipe.description,
                    cookTime: recipe.cookTime)
                self.delegate?.handleViewModelOutput(.saved)
            } catch{
                self.delegate?.handleViewModelOutput(.showError(error))
            }
        } else {
            let error = NSError()
            self.delegate?.handleViewModelOutput(.showError(error))
        }
    }
    
    func separateJson(json: String) -> Data? {
        if let startIndex = json.range(of: "{"),
           let endIndex = json.range(of: "}", options: .backwards) {
            let jsonSubstring = json[startIndex.upperBound...endIndex.lowerBound]
            var jsonString = json
            return jsonString.data(using: .utf8)
        }
        return nil
    }
}

extension ImageToTextViewModeOutput {
    static func == (lhs: ImageToTextViewModeOutput, rhs: ImageToTextViewModeOutput) -> Bool {
        switch (lhs, rhs) {
        case (.setLoading(let a), .setLoading(let b)):
            return a == b
        case (.showRecipe(let a), .showRecipe(let b)):
            return a == b
        default:
            return false
        }
    }
}
