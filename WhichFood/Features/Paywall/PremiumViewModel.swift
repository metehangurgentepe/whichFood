//
//  PremiumViewModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 22.10.2023.
//

import Foundation
import RevenueCat


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

class PremiumViewModel: PremiumViewModelProtocol{
    
    weak var delegate: PremiumViewControllerDelegate?
    var offering : Offering?
    
    func fetchOfferings() {
        if let package = self.offering?.availablePackages {
            print(package)
            self.delegate?.handleViewModelOutput(.getAllOfferings(package))
        }
    }
    
    func getCustomerInfo() {
        Purchases.shared.getCustomerInfo {[weak self] info, error in
            if let error = error{
                self?.delegate?.handleViewModelOutput(.showError(error))
            }
            
            /// info is not nil
            if let info = info {
                if !info.activeSubscriptions.isEmpty {
                    self?.delegate?.handleViewModelOutput(.userIsPremium(true))
                    self?.delegate?.handleViewModelOutput(.getUserInfo(info))
                } else {
                    self?.delegate?.handleViewModelOutput(.userIsPremium(false))
                }
            }
        }
    }
    
    func fetchPackage(){
        Task { [weak self] in
            self?.delegate?.handleViewModelOutput(.setLoading(true))
            Purchases.shared.getOfferings { offerings, error in
                if let error = error {
                    self?.delegate?.handleViewModelOutput(.showError(error))
                }
                if let offering = offerings?.current {
                    self?.offering = offering
                    self?.delegate?.handleViewModelOutput(.getOfferings((offering)))
                }
            }
            self?.delegate?.handleViewModelOutput(.setLoading(false))
        }
    }
    
    func purchase(package:  RevenueCat.Package) async throws{
        DispatchQueue.main.async{
            self.delegate?.handleViewModelOutput(.setLoading(true))
            Purchases.shared.purchase(package: package) { transaction, info, error, userCancelled in
                if let error = error {
                    self.delegate?.handleViewModelOutput(.showError(error))
                } else {
                    if info?.entitlements["pro"]?.isActive == true {
                        Task{
                            try await UserManager.shared.makeUserPremium(subscribeType: package.identifier)
                            self.delegate?.handleViewModelOutput(.userBecamePremium)
                        }
                    }
                }
                if userCancelled {
                    self.delegate?.handleViewModelOutput(.setLoading(false))
                }
            }
            self.delegate?.handleViewModelOutput(.setLoading(false))
        }
    }
    
    func restorePurchases() {
        self.delegate?.handleViewModelOutput(.showAlert)
        Purchases.shared.restorePurchases()
    }
}

extension PremiumViewModelOutput {
    static func == (lhs: PremiumViewModelOutput, rhs: PremiumViewModelOutput) -> Bool {
        switch (lhs, rhs) {
        case (.setLoading(let a), .setLoading(let b)):
            return a == b
        case (.getOfferings(let a), .getOfferings(let b)):
            return a == b
        default:
            return false
        }
    }
}
