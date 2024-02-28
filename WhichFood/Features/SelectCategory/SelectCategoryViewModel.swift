//
//  SelectCategoryViewModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 19.09.2023.
//

import Foundation

protocol SelectCategoryViewModelProtocol {
    var delegate: SelectCategoryVCDelegate? {get set}
}

class SelectCategoryViewModel: SelectCategoryViewModelProtocol {
    weak var delegate: SelectCategoryVCDelegate?

    var titles: [Category] = [
        Category(title: Categories.easy, isSelected: false),
        Category(title: Categories.mid, isSelected: false),
        Category(title: Categories.hard, isSelected: false),
        Category(title: Categories.healthy, isSelected: false),
        Category(title: Categories.enjoy, isSelected: false),
        Category(title: Categories.hearty, isSelected: false),
        Category(title: Categories.vegan, isSelected: false),
        Category(title: Categories.dessert, isSelected: false),
        Category(title: Categories.vegetarian, isSelected: false),
        Category(title: Categories.breakfast, isSelected: false),
        Category(title: Categories.lunch, isSelected: false),
        Category(title: Categories.dinner, isSelected: false),
    ]
    
}
