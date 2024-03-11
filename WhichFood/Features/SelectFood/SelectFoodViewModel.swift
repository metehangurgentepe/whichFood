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
    
    func chooseIngredient(ingredient: Ingredient)
    func inSearchMode(_ searchController: UISearchController) -> Bool
    func updateSearchController(searchBarText: String?)
    
}

final class SelectFoodViewModel: SelectFoodViewModelProtocol {
    
    weak var view: SelectFoodViewDelegate?
    
    var foods: [Ingredient] = [
        Ingredient(name: LocaleKeys.Ingredient.fish.rawValue.locale(), category: .meat, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.lamb.rawValue.locale(), category: .meat, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.turkey.rawValue.locale(), category: .meat, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.beef.rawValue.locale(), category: .meat, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.sausage.rawValue.locale(), category: .meat, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.groundBeef.rawValue.locale(), category: .meat, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.chicken.rawValue.locale(), category: .meat, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.dicedBeef.rawValue.locale(), category: .meat, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.pastrami.rawValue.locale(), category: .meat, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.calamari.rawValue.locale(), category: .seafood, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.egg.rawValue.locale(), category: .dairy, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.cheese.rawValue.locale(), category: .dairy, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.yogurt.rawValue.locale(), category: .dairy, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.milk.rawValue.locale(), category: .dairy, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.cream.rawValue.locale(), category: .dairy, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.ricotta.rawValue.locale(), category: .dairy, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.bread.rawValue.locale(), category: .grain, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.thyme.rawValue.locale(), category: .herb, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.parsley.rawValue.locale(), category: .herb, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.freshBasil.rawValue.locale(), category: .herb, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.freshMint.rawValue.locale(), category: .herb, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.garlic.rawValue.locale(), category: .vegetable, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.tomato.rawValue.locale(), category: .vegetable, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.carrot.rawValue.locale(), category: .vegetable, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.potato.rawValue.locale(), category: .vegetable, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.springOnion.rawValue.locale(), category: .vegetable, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.pepper.rawValue.locale(), category: .vegetable, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.zucchini.rawValue.locale(), category: .vegetable, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.eggplant.rawValue.locale(), category: .vegetable, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.mushroom.rawValue.locale(), category: .vegetable, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.lettuce.rawValue.locale(), category: .vegetable, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.peas.rawValue, category: .vegetable, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.spinach.rawValue.locale(), category: .vegetable, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.celery.rawValue.locale(), category: .vegetable, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.lemon.rawValue.locale(), category: .fruit, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.avocado.rawValue.locale(),category: .fruit,isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.grape.rawValue.locale(), category: .fruit, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.fig.rawValue.locale(), category: .fruit, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.orange.rawValue.locale(), category: .fruit, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.strawberry.rawValue.locale(), category: .fruit, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.raspberry.rawValue.locale(), category: .fruit, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.blackberry.rawValue.locale(), category: .fruit, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.mulberry.rawValue.locale(), category: .fruit, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.kiwi.rawValue.locale(), category: .fruit, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.apple.rawValue.locale(), category: .fruit, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.pomegranate.rawValue.locale(), category: .fruit, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.quince.rawValue.locale(), category: .fruit, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.walnut.rawValue.locale(), category: .nut, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.pistachio.rawValue.locale(), category: .nut, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.coconut.rawValue.locale(), category: .nut, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.almond.rawValue.locale(), category: .nut, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.hazelnut.rawValue.locale(), category: .nut, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.shrimp.rawValue.locale(), category: .seafood, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.salmon.rawValue.locale(), category: .seafood, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.clams.rawValue.locale(), category: .seafood, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.scallops.rawValue.locale(), category: .seafood, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.lobster.rawValue.locale(), category: .seafood, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.crab.rawValue.locale(), category: .seafood, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.prawns.rawValue.locale(), category: .seafood, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.caviar.rawValue.locale(), category: .seafood, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.oysters.rawValue.locale(), category: .seafood, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.mussels.rawValue.locale(), category: .seafood, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.anchovies.rawValue.locale(), category: .seafood, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.sardines.rawValue.locale(), category: .seafood, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.haddock.rawValue.locale(), category: .seafood, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.cod.rawValue.locale(), category: .seafood, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.tuna.rawValue.locale(), category: .seafood, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.trout.rawValue.locale(), category: .seafood, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.duck.rawValue.locale(), category: .meat, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.veal.rawValue.locale(), category: .meat, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.rabbit.rawValue.locale(), category: .meat, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.quail.rawValue.locale(), category: .meat, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.pork.rawValue.locale(), category: .meat, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.bacon.rawValue.locale(), category: .meat, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.ham.rawValue.locale(), category: .meat, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.sausage.rawValue.locale(), category: .meat, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.cabbage.rawValue.locale(), category: .vegetable, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.broccoli.rawValue.locale(), category: .vegetable, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.cauliflower.rawValue.locale(), category: .vegetable, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.asparagus.rawValue.locale(), category: .vegetable, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.artichoke.rawValue.locale(), category: .vegetable, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.kale.rawValue.locale(), category: .vegetable, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.brusselsSprouts.rawValue.locale(), category: .vegetable, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.cucumber.rawValue.locale(), category: .vegetable, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.radish.rawValue.locale(), category: .vegetable, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.sweetPotato.rawValue.locale(), category: .vegetable, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.beetroot.rawValue.locale(), category: .vegetable, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.pumpkin.rawValue.locale(), category: .vegetable, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.turnip.rawValue.locale(), category: .vegetable, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.okra.rawValue.locale(), category: .vegetable, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.blueberry.rawValue.locale(), category: .fruit, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.cranberry.rawValue.locale(), category: .fruit, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.watermelon.rawValue.locale(), category: .fruit, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.papaya.rawValue.locale(), category: .fruit, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.pineapple.rawValue.locale(), category: .fruit, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.mango.rawValue.locale(), category: .fruit, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.passionFruit.rawValue.locale(), category: .fruit, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.date.rawValue.locale(), category: .fruit, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.dragonFruit.rawValue.locale(), category: .fruit, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.persimmon.rawValue.locale(), category: .fruit, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.starFruit.rawValue.locale(), category: .fruit, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.pomegranate.rawValue.locale(), category: .fruit, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.blackCurrant.rawValue.locale(), category: .fruit, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.rosemary.rawValue.locale(), category: .herb, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.sage.rawValue.locale(), category: .herb, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.mint.rawValue.locale(), category: .herb, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.cilantro.rawValue.locale(), category: .herb, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.bayLeaf.rawValue.locale(), category: .herb, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.oregano.rawValue.locale(), category: .herb, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.tarragon.rawValue.locale(), category: .herb, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.chives.rawValue.locale(), category: .herb, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.lemongrass.rawValue.locale(), category: .herb, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.marjoram.rawValue.locale(), category: .herb, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.coriander.rawValue.locale(), category: .herb, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.basil.rawValue.locale(), category: .herb, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.walnut.rawValue.locale(), category: .nut, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.pistachio.rawValue.locale(), category: .nut, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.cashew.rawValue.locale(), category: .nut, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.hazelnut.rawValue.locale(), category: .nut, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.macadamia.rawValue.locale(), category: .nut, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.pineNuts.rawValue.locale(), category: .nut, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.pecan.rawValue.locale(), category: .nut, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.almond.rawValue.locale(), category: .nut, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.peanut.rawValue.locale(), category: .nut, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.cocoa.rawValue.locale(), category: .nut, isSelected: false),
        Ingredient(name: LocaleKeys.Ingredient.chestnut.rawValue.locale(), category: .nut, isSelected: false)
    ]
    
    weak var delegate: SelectFoodViewDelegate?
    var filteredFoods = [Ingredient]()
    private (set) var selectedFoods : [Ingredient] = []
    
    var categorizedIngredients: [String: [Ingredient]] = [:]
    
    init() {
        let sortedFoods = foods.sorted { $0.category.rawValue < $1.category.rawValue }
        
        for ingredient in sortedFoods {
            let categoryKey = ingredient.category.localizedValue
            if categorizedIngredients[categoryKey] == nil {
                categorizedIngredients[categoryKey] = [ingredient]
            } else {
                categorizedIngredients[categoryKey]?.append(ingredient)
            }
        }
    }
    
    
    func chooseIngredient(ingredient: Ingredient) {
        if selectedFoods.contains(where: { $0.name == ingredient.name }) {
            if let removedIndex = selectedFoods.firstIndex(where: { $0.name == ingredient.name }) {
                selectedFoods.remove(at: removedIndex)
            }
        } else {
            selectedFoods.append(ingredient)
        }
    }
    
    
    
    func increaseApiUsage() async throws {
        self.delegate?.buttonLoading(isLoading: true)
        do{
            try await UserManager.shared.increaseApiUsage()
            self.delegate?.navigate()
        } catch {
            self.delegate?.onError(error as! WFError)
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



