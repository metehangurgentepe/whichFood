//
//  PremiumViewModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 22.10.2023.
//

import Foundation
import RevenueCat


class PaywallViewModel: ObservableObject {
    @Published var offerings: Offerings?
    @Published var currentOffering: Offering?
    @Published var selectedPackage: Package?
    @Published var isLoading = false
    @Published var isPurchasing = false
    @Published var errorMessage: String?
    @Published var isLifetimeFree = false
    private let userDefaults = UserDefaults(suiteName: "group.com.metehangurgentepe.findmycar")
    private let premiumStatusKey = "isPremiumUser"
    
    init() {
        setupRevenueCat()
        fetchOfferings()
        checkIfLifetimeIsFree()
    }
    
    private func checkIfLifetimeIsFree() {
        guard let lifetimePackage = currentOffering?.availablePackages.first(where: { $0.packageType == .lifetime }) else {
            isLifetimeFree = false
            return
        }
        
        let price = NSDecimalNumber(decimal: lifetimePackage.storeProduct.price).doubleValue
        isLifetimeFree = (price == 0.0)
    }
    
    func formatPrice(for package: Package) -> String {
        let price = package.localizedPriceString
        
        switch package.packageType {
        case .monthly:
            return "\(price)/month"
        case .lifetime:
            return price
        default:
            return package.localizedPriceString
        }
    }
    
    private func setupRevenueCat() {
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String {
            Purchases.configure(withAPIKey: apiKey)
        }
    }
    
    func fetchOfferings() {
        isLoading = true
        
        Purchases.shared.getOfferings { [weak self] offerings, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                self?.offerings = offerings
                self?.currentOffering = offerings?.current
                self?.selectedPackage = offerings?.current?.availablePackages.first
                self?.checkIfLifetimeIsFree()
            }
        }
    }
    
    func restorePurchases() {
        isLoading = true
        
        Purchases.shared.restorePurchases { [weak self] customerInfo, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                if customerInfo?.entitlements.all["pro"]?.isActive == true {
                    NotificationCenter.default.post(name: NSNotification.Name("PurchaseSuccessful"), object: nil)
                    self?.userDefaults?.set(true, forKey: self?.premiumStatusKey ?? "")
                    self?.userDefaults?.synchronize()

                    // Sync premium status to Firebase
                    Task {
                        do {
                            _ = try await UserManager.shared.checkPremiumStatus()
                            print("✅ Premium status synced to Firebase after restore")
                        } catch {
                            print("❌ Failed to sync premium status to Firebase: \(error)")
                        }
                    }
                } else {
                    self?.errorMessage = "No previous purchases found"

                    // Also sync non-premium status to Firebase
                    Task {
                        do {
                            _ = try await UserManager.shared.checkPremiumStatus()
                        } catch {
                            print("❌ Failed to sync premium status to Firebase: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    func purchase(package: Package) {
        isPurchasing = true
        
        Purchases.shared.purchase(package: package) { [weak self] transaction, customerInfo, error, userCancelled in
            DispatchQueue.main.async {
                defer {
                    self?.isPurchasing = false
                }
                
                if userCancelled {
                    return
                }
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                if customerInfo?.entitlements.all["pro"]?.isActive == true {
                    self?.userDefaults?.set(true, forKey: self?.premiumStatusKey ?? "")
                    self?.userDefaults?.synchronize()
                    NotificationCenter.default.post(name: NSNotification.Name("PurchaseSuccessful"), object: nil)

                    // Sync premium status to Firebase
                    Task {
                        do {
                            _ = try await UserManager.shared.checkPremiumStatus()
                            print("✅ Premium status synced to Firebase after purchase")
                        } catch {
                            print("❌ Failed to sync premium status to Firebase: \(error)")
                        }
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        self?.showRateApp()
                    }
                } else {
                    self?.errorMessage = "Purchase failed. Please try again."
                }
            }
        }
    }
    
    private func showRateApp() {
//        RateAppController.shared.showRateApp()
    }
    
    func calculateSavings(for package: Package) -> String? {
        guard let monthly = currentOffering?.monthly else { return nil }

        let monthlyPrice = NSDecimalNumber(decimal: monthly.storeProduct.price).doubleValue
        let packagePrice = NSDecimalNumber(decimal: package.storeProduct.price).doubleValue

        switch package.packageType {
        case .annual:
            let monthlyEquivalent = packagePrice / 12
            let savings = ((monthlyPrice - monthlyEquivalent) / monthlyPrice) * 100
            return String(format: LocaleKeys.Paywall.discountPercent.rawValue.locale(), Int(round(savings)))
        case .lifetime:
            return LocaleKeys.Paywall.bestValue.rawValue.locale()
        default:
            return nil
        }
    }
}
