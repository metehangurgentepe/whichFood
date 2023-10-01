//
//  SelectFoodViewModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 12.09.2023.
//

import Foundation

class SelectFoodViewModel {
    
    var onFoodsUpdated: (()->Void)?
    
    private (set) var foods : [Ingredient] = [] {
        didSet{
            self.onFoodsUpdated?()
        }
    }
    
    private (set) var selectedFoods : [Ingredient] = []
    
    
    
    init() {
        self.fetchFoods()
    }
    
    func fetchFoods() {
        let allFoods : [Ingredient] =
        [
            Ingredient(name: "Patates", category: .vegetable, isSelected: false),
            Ingredient(name: "Salatalık", category: .vegetable, isSelected: false),
            Ingredient(name: "Domates", category: .vegetable, isSelected: false),
            Ingredient(name: "Limon", category: .vegetable, isSelected: false),
            Ingredient(name: "Tavuk", category: .meat, isSelected: false),
            Ingredient(name: "Kırmızı Et", category: .meat, isSelected: false),
            Ingredient(name: "Süt", category: .dairyProducts, isSelected: false),
            Ingredient(name: "Peynir", category: .dairyProducts, isSelected: false),
            Ingredient(name: "Yumurta", category: .dairyProducts, isSelected: false),
            Ingredient(name: "Pirinç", category: .grain, isSelected: false)
        ]
        foods = allFoods
    }
    
    func chooseFood(index: Int) {
        foods[index].isSelected = !foods[index].isSelected
        selectedFoods = foods.compactMap { foods in
            return foods.isSelected ? foods : nil
        }
    }
    
    func filterFoods(searchText: String) {
        self.foods = foods.compactMap { foods in
            return foods.name.lowercased().contains(searchText.lowercased()) ? foods : nil
        }
    }
    
    func inSearchMode(searchText: String) -> Bool {
        return !searchText.isEmpty
    }
}
