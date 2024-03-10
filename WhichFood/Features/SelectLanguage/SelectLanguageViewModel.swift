//
//  SelectLanguageViewModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 7.11.2023.
//

import Foundation
import UIKit

enum SelectLanguageViewModelOutput {
    case showPopUp(vc: UIViewController)
    case showError(Error)
}

protocol SelectLanguageViewModelProtocol: AnyObject {
    func handleViewModelOutput(_ output: SelectLanguageViewModelOutput)
}


class SelectLanguageViewModel {
    
    var models: [LanguageModel] = []
    weak var delegate: SelectLanguageViewModelProtocol?
    
    func appendRowTableview() {
        models.append(LanguageModel(title: "Spanish", handler: {
            let path = Bundle.main.path(forResource: "es", ofType: "lproj")
            let bundle = Bundle(path: path!)
            let localizedText = bundle!.localizedString(forKey: <#T##String#>, value: <#T##String?#>, table: <#T##String?#>)
        }))
        
        models.append(LanguageModel(title: "German", handler: {
            print("german")
        }))
    }
}
