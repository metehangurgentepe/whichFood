//
//  SelectFoodViewModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 12.09.2023.
//

import Foundation
import UIKit

protocol SelectFoodViewModelProtocol{
    var delegate: SelectFoodViewDelegate? {get set}
    
    func chooseIngredient(index: Int, searchController : UISearchController)
    func inSearchMode(_ searchController: UISearchController) -> Bool
    func updateSearchController(searchBarText: String?)
    
}

final class SelectFoodViewModel: SelectFoodViewModelProtocol {
    
    weak var view: SelectFoodViewDelegate?
    
    var foods: [Ingredient] = [
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.fish.rawValue, comment: "Balık"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.lamb.rawValue, comment: "Kuzu"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.turkey.rawValue, comment: "Hindi"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.beef.rawValue, comment: "Sığır Et"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.sausage.rawValue, comment: "Sosis"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.calamari.rawValue, comment: "Kalamar"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.pastrami.rawValue, comment: "Pastırma"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.butter.rawValue, comment: "Tereyağı"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.rice.rawValue, comment: "Pirinç"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.garlic.rawValue, comment: "Sarımsak"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.parsley.rawValue, comment: "Maydanoz"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.tomato.rawValue, comment: "Domates"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.carrot.rawValue, comment: "Havuç"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.potato.rawValue, comment: "Patates"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.springOnion.rawValue, comment: "Taze Soğan"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.pepper.rawValue, comment: "Biber"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.zucchini.rawValue, comment: "Kabak"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.eggplant.rawValue, comment: "Patlıcan"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.mushroom.rawValue, comment: "Mantar"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.freshBasil.rawValue, comment: "Taze Fesleğen"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.lettuce.rawValue, comment: "Marul"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.peas.rawValue, comment: "Bezelye"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.spinach.rawValue, comment: "Ispanak"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.freshMint.rawValue, comment: "Taze Nane"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.celery.rawValue, comment: "Kereviz"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.thyme.rawValue, comment: "Kekik"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.egg.rawValue, comment: "Yumurta"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.groundBeef.rawValue, comment: "Kıyma"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.chicken.rawValue, comment: "Tavuk"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.dicedBeef.rawValue, comment: "Küp Kıyma"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.bread.rawValue, comment: "Ekmek"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.cheese.rawValue, comment: "Peynir"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.yogurt.rawValue, comment: "Yoğurt"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.milk.rawValue, comment: "Süt"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.cream.rawValue, comment: "Krema"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.ricotta.rawValue, comment: "Ricotta Peyniri"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.lemon.rawValue, comment: "Limon"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.avocado.rawValue, comment: "Avokado"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.grape.rawValue, comment: "Üzüm"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.fig.rawValue, comment: "İncir"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.orange.rawValue, comment: "Portakal"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.strawberry.rawValue, comment: "Çilek"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.raspberry.rawValue, comment: "Ahududu"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.blackberry.rawValue, comment: "Böğürtlen"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.mulberry.rawValue, comment: "Dut"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.kiwi.rawValue, comment: "Kivi"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.apple.rawValue, comment: "Elma"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.pomegranate.rawValue, comment: "Nar"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.quince.rawValue, comment: "Ayva"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.walnut.rawValue, comment: "Ceviz"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.pistachio.rawValue, comment: "Antep Fıstığı"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.coconut.rawValue, comment: "Hindistancevizi"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.almond.rawValue, comment: "Badem"), category: .vegetable, isSelected: false),
        Ingredient(name: NSLocalizedString(LocaleKeys.Ingredient.hazelnut.rawValue, comment: "Findik"), category: .vegetable, isSelected: false),
    ] { didSet {
        //        onRecipesUpdated?()
    }}
    
    weak var delegate: SelectFoodViewDelegate?
    var filteredFoods = [Ingredient]()
    private (set) var selectedFoods : [Ingredient] = []
    
    func chooseIngredient(index: Int, searchController : UISearchController){
        var ingredient = inSearchMode(searchController) ? filteredFoods[index] : foods[index]
        
        if inSearchMode(searchController) {
            filteredFoods[index].isSelected = !filteredFoods[index].isSelected
            if let ingredientIndexInFoods = foods.firstIndex(where: { $0.name == filteredFoods[index].name }) {
                foods[ingredientIndexInFoods].isSelected = filteredFoods[index].isSelected
            }
        } else{
            foods[index].isSelected = !foods[index].isSelected
        }
        
        if selectedFoods.contains(where: {$0.name == ingredient.name}) {
            if let removedIndex = selectedFoods.firstIndex(where: {$0.name == ingredient.name}) {
                selectedFoods.remove(at: removedIndex)
            }
            if inSearchMode(searchController) {
                filteredFoods[index].isSelected = false
            } else {
                foods[index].isSelected = false
            }
        } else {
            selectedFoods.append(ingredient)
            if inSearchMode(searchController) {
                filteredFoods[index].isSelected = true
            } else {
                foods[index].isSelected = true
            }
        }
        self.delegate?.onIngredientsUpdated()
    }
    
    func increaseApiUsage() async throws {
        self.delegate?.buttonLoading(isLoading: true)
        do{
            try await UserManager.shared.increaseApiUsage()
            self.delegate?.navigate()
        } catch {
            self.delegate?.onError(error)
        }
        self.delegate?.buttonLoading(isLoading: false)
    }
}

extension SelectFoodViewModel {
    public func inSearchMode(_ searchController: UISearchController) -> Bool {
        let isActive = searchController.isActive
        let searchText = searchController.searchBar.text ?? ""
        
        return isActive && !searchText.isEmpty
    }
    
    public func updateSearchController(searchBarText: String?) {
        self.filteredFoods = foods
        
        if let searchText = searchBarText?.lowercased() {
            guard !searchText.isEmpty else { self.delegate?.onIngredientsUpdated(); return }
            
            self.filteredFoods = self.filteredFoods.filter({$0.name.lowercased().contains(searchText)})
            self.delegate?.onIngredientsUpdated()
        }
    }
}



