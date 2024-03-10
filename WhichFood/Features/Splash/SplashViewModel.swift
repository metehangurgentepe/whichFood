//
//  SplashViewModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 11.11.2023.
//

import Foundation
import RevenueCat
import FirebaseAuth


protocol SplashViewModelProtocol {
    var delegate: SplashViewDelegate? {get set}
    func createUser() async throws
    func getKeychain() async -> String?
    func saveKeychain() throws
    func signIn()
}

class SplashViewModel: SplashViewModelProtocol {
    weak var delegate: SplashViewDelegate?
    
    var userID: String?
    
    func createUser() async throws{
        do {
            try await UserManager.shared.createUser()
        } catch {
            self.delegate?.showError(error)
        }
    }
    
    func saveKeychain() throws{
        do{
           try KeychainManager.save(account: "account")
        } catch {
            switch error {
            case KeychainError.duplicateEntry:
                print("duplicate")
            default:
                print(error)
            }
        }
    }
    
    func getKeychain() async -> String? {
        let onboarding = await OnboardingVC()
        let home = await MainTabBarController()

        if let data = KeychainManager.get(account: "account") {
            let id = String(decoding: data, as: UTF8.self)

            await MainActor.run {
//                home.hidesBottomBarWhenPushed = true
                self.delegate?.navigate(vc: home)
            }
            return id
        } else {
            do {
                try self.saveKeychain()
                try await createUser()
                
                print("Before navigate to onboarding")
                await MainActor.run {
                    self.delegate?.navigateToOnboarding()
                }
                print("After navigate to onboarding")
            } catch {
                print(error)
            }
        }
        return nil
    }

    
    func signIn() {
//        Auth.auth().signInAnonymously()
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

            // Now 'customerInfo' should have the correct type (CustomerInfo?).

            if let info = customerInfo {
                if !info.activeSubscriptions.isEmpty {
                    try await UserManager.shared.makeUserPremium(subscribeType: info.activeSubscriptions.first?.description ?? "")
                } else {
                    try await UserManager.shared.makeUserNullPremium()
                }
            }
        } catch {
            print(error)
        }
    }
}
