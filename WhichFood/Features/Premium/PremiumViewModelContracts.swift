//
//  PremiumViewModelContracts.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 14.03.2024.
//

import Foundation
import RevenueCat

protocol PremiumViewControllerDelegate : AnyObject {
    func handleViewModelOutput(_ output: PremiumViewModelOutput)
}

enum PremiumViewModelOutput: Equatable {
    case setLoading(Bool)
    case getOfferings(Offering)
    case showError(Error)
    case getAllOfferings([Package])
    case userIsPremium(Bool)
    case getUserInfo(CustomerInfo)
    case userBecamePremium
    case showAlert
}

protocol PremiumViewModelProtocol {
    var delegate: PremiumViewControllerDelegate? {get set}
    func fetchPackage()
    func purchase(package: RevenueCat.Package) async throws
    func getCustomerInfo()
}
