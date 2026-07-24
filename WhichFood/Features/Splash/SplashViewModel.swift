//
//  SplashViewModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 11.11.2023.
//

import Foundation
import RevenueCat
import FirebaseAuth

// NOTE: Ensure SplashViewDelegate defines: func navigateToMainTabBar(isPremium: Bool, vendorID: String)

protocol SplashViewModelProtocol {
    var delegate: SplashViewDelegate? {get set}
    func createUser() async throws
    func getKeychain() async -> String?
    func saveKeychain() throws
    func signIn()
    func checkPremiumStatus() async -> Bool
}

class SplashViewModel: SplashViewModelProtocol {
    
    func signIn() {
        
    }
    
    weak var delegate: SplashViewDelegate?
    
    var userID: String?
    
    func createUser() async throws{
        do {
            try await UserManager.shared.createUser()
        } catch {
//            self.delegate?.showError(error)
        }
    }
    
    func saveKeychain() throws{
        do{
           try KeychainManager.save(account: "account")
        } catch {
            switch error {
            case KeychainError.duplicateEntry:
//                self.delegate?.showError(KeychainError.duplicateEntry)
                break
            default:
//                self.delegate?.showError(error)
                break
            }
        }
    }
    
    func getKeychain() async -> String? {

        if let data = KeychainManager.get(account: "account") {
            let id = String(decoding: data, as: UTF8.self)
            let isPremium = await checkPremiumStatus()

            await MainActor.run {
                self.delegate?.navigateToMainTabBar(isPremium: isPremium, vendorID: id)
            }
            return id
        } else {
            do {
                try self.saveKeychain()
                try await createUser()

                await MainActor.run {
                    self.delegate?.navigateToOnboarding()
                }
            } catch {
//                self.delegate?.showError(error)
            }
        }
        return nil
    }

    
    func fetchUser() async throws {
        do {
            let customerInfo = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CustomerInfo?, Error>) in
                Purchases.shared.getCustomerInfo { info, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: info)
                    }
                }
            }


            if let info = customerInfo {
                if !info.activeSubscriptions.isEmpty {
                    try await UserManager.shared.makeUserPremium(subscribeType: info.activeSubscriptions.first?.description ?? "")
                } else {
                    try await UserManager.shared.makeUserNullPremium()
                }
            }
            
        } catch {
//            self.delegate?.showError(error)
        }
    }

    func checkPremiumStatus() async -> Bool {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            let isPremium = customerInfo.entitlements.all["pro"]?.isActive == true

            print("🔍 SplashView Premium Check:")
            print("💎 Pro Entitlement Active: \(isPremium)")

            return isPremium
        } catch {
            print("❌ Error checking premium status in SplashView: \(error)")
            return false
        }
    }
}

