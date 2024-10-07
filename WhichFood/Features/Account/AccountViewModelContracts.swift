//
//  AccountViewModelContracts.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 14.03.2024.
//

import Foundation
import UIKit

protocol AccountViewModelDelegate: AnyObject {
    func handleViewModelOutput(_ output: AccountViewModelOutput)
}

enum AccountViewModelOutput {
    case getUser(User)
    case showError(Error)
    case setLoading(Bool)
    case getTableViews([AccountInfo])
    case tappedRow(index:Int)
    case navigate(vc: UIViewController)
}

protocol AccountViewModelProtocol {
    var delegate: AccountViewModelDelegate? {get set}
    func getUser(completion: @escaping () -> Void)
    func createTableView()
}
