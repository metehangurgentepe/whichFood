//
//  SettingsViewModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 26.09.2023.
//

import Foundation
import UIKit

protocol SettingsViewModelDelegate: AnyObject {
    func didFinish()
    func didFail(error:Error)
}


class SettingsViewModel{
    weak var delegate: SettingsViewModelDelegate?
    
    private(set) var userId: String = ""
    
    func getUserId() -> String {
        let userId = UIDevice.current.identifierForVendor?.uuidString
        let string = "User ID: \(userId ?? "")"
        return string
    }
    
}
