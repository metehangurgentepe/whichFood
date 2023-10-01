//
//  HomeViewModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 15.09.2023.
//

import Foundation

protocol HomeViewModelDelegate: AnyObject{
    func didFinish()
    func didFail(error: Error)
    func isLoading()
   // var isLoading: Bool { get set }
}

class HomeViewModel{
    weak var delegate: HomeViewModelDelegate?
    
    private(set) var recipes : [Recipe] = []
    
    
    @MainActor
    func getRecipes() {
        Task{ [weak self] in
       //     self?.delegate?.isLoading = true
            self?.delegate?.isLoading()
            do {
                self?.recipes = try await SavedRecipesManager.shared.getAllRecipes()
                self?.delegate?.didFinish()
               // self?.delegate?.isLoading = false
            } catch{
                self?.delegate?.didFail(error: error)
              //  self?.delegate?.isLoading = false
            }
        }
    }
    
    func delete(id: String,index: Int) {
        SavedRecipesManager.shared.deleteRecipe(id: id)
        recipes.remove(at: index)
    }
    
    func formatDate(_ dateString: String) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        
        if let date = dateFormatter.date(from: dateString) {
            dateFormatter.dateFormat = "dd MMMM yyyy"
            dateFormatter.locale = Locale(identifier: "tr_TR") // Türkçe formatı
            return dateFormatter.string(from: date)
        } else {
            return nil // Tarih çözümlenemezse nil döndürün.
        }
    }
}
