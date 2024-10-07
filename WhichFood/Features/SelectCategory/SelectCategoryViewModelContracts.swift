//
//  SelectCategoryViewModelContracts.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 14.03.2024.
//

import Foundation

protocol SelectCategoryViewModelProtocol {
    var delegate: SelectCategoryVCDelegate? {get set}
}

protocol SelectCategoryVCDelegate: AnyObject {
    //    func nextButtonClicked()
    //    func changeStateButton(button: UIButton)
}
