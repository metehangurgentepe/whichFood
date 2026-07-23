//
//  TabBarController.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 3.12.2023.
//

import Foundation
import UIKit
import SwiftUI
import RevenueCat
import FirebaseAuth
import FirebaseFirestore

struct SettingsViewWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let settingsVC = UIHostingController(rootView: SettingsView())
        return settingsVC
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}


class MainTabBarController: UITabBarController {

    var isPremiumFromSplash: Bool = false
    private var hasCheckedPremiumOnAppear = false
    
    var vendorID: String? // Set this from SplashView before presenting the tab bar

    private func updateFirebasePremiumFlag(isPremium: Bool) {
        // Prefer SplashView-provided vendorID, otherwise fall back to Firebase Auth UID
        let documentID: String? = {
            if let vendorID = self.vendorID, !vendorID.isEmpty {
                return vendorID
            }
            return Auth.auth().currentUser?.uid
        }()

        guard let documentID else {
            print("ℹ️ Firebase: No vendorID or authenticated user. Skipping premium flag update.")
            return
        }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(documentID)
        let data: [String: Any] = [
            "isPremium": isPremium,
            "premiumUpdatedAt": FieldValue.serverTimestamp()
        ]

        userRef.setData(data, merge: true) { error in
            if let error = error {
                print("❌ Firebase: Failed to update premium flag: \(error)")
            } else {
                print("✅ Firebase: Premium flag updated (isPremium=\(isPremium))")
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Ensure we only check once on first appearance to avoid repeated presentations
        guard !hasCheckedPremiumOnAppear else { return }
        hasCheckedPremiumOnAppear = true

        // If splash already confirmed premium, skip. Otherwise, check with RevenueCat
        if isPremiumFromSplash {
            return
        }
        checkPremiumAndShowPaywall()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupTabs()
        setupTabBar()
    }
    
    func checkPremiumAndShowPaywall() {
        Task {
            do {
                let customerInfo = try await Purchases.shared.customerInfo()
                let isPremium = customerInfo.entitlements.all["pro"]?.isActive == true

                print("🔍 RevenueCat Premium Check:")
                print("📊 Customer Info: \(customerInfo)")
                print("🎯 Entitlements: \(customerInfo.entitlements.all)")
                print("💎 Pro Entitlement Active: \(isPremium)")

                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if !isPremium {
                        print("❌ User is NOT premium - showing paywall")
                        self.updateFirebasePremiumFlag(isPremium: false)
                        self.showPaywallUI()
                    } else {
                        print("✅ User IS premium - no paywall needed")
                        self.updateFirebasePremiumFlag(isPremium: true)
                    }
                }
            } catch {
                print("❌ Error checking premium status from RevenueCat: \(error)")
                // On error, show paywall as fallback
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    print("⚠️ Error occurred - showing paywall as fallback")
                    self.updateFirebasePremiumFlag(isPremium: false)
                    self.showPaywallUI()
                }
            }
        }
    }

    private func showPaywallUI() {
        // Avoid multiple presentations of the paywall
        if presentedViewController is UIHostingController<SubscriptionView> {
            return
        }
        
        let paywallView = SubscriptionView()
        let hostingController = UIHostingController(rootView: paywallView)

        // Full screen modal presentation
        hostingController.modalPresentationStyle = .fullScreen
        hostingController.modalTransitionStyle = .coverVertical

        present(hostingController, animated: true)
    }

    func showPaywall() {
        print("📱 Request to show paywall from TabBar")
        showPaywallUI()
    }

    // MARK: - Public Premium Check Functions

    /// Call this function when you want to check premium status and show paywall if not premium
    public func checkAndShowPaywallIfNeeded() {
        checkPremiumAndShowPaywall()
    }

    /// Check if user is premium without showing paywall
    public func isPremiumUser(completion: @escaping (Bool) -> Void) {
        Purchases.shared.getCustomerInfo { (customerInfo, error) in
            if let error = error {
                print("❌ Error fetching customer info: \(error)")
                completion(false)
                return
            }

            guard let entitlements = customerInfo?.entitlements else {
                print("❌ No entitlements found")
                completion(false)
                return
            }

            let isPremium = entitlements["pro"]?.isActive == true
            print("🔍 isPremiumUser (callback) check: \(isPremium)")
            completion(isPremium)
        }
    }
    
    fileprivate func setupTabBar() {
        navigationItem.hidesBackButton = true
        tabBar.tintColor = Colors.primary.color
        
        tabBar.isTranslucent = true
        tabBar.barStyle = .default
        
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = tabBar.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tabBar.insertSubview(blurEffectView, at: 0)
        
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])
    }
    
    
    private func setupTabs() {
        let home = self.createNav(
            with: LocaleKeys.Home.recipe.rawValue.locale(),
            and: Images.home,
            vc: HomeViewController())
        let search = self.createNav(
            with: LocaleKeys.Home.search.rawValue.locale(),
            and: Images.search,
            vc: SearchViewController())
        let favorites = self.createNav(
            with: LocaleKeys.Home.favorites.rawValue.locale(),
            and: Images.fav,
            vc: FavoriteViewController())
        let settings = self.createNav(
            with: LocaleKeys.Settings.title.rawValue.locale(),
            and: Images.settings,
            vc: SettingsVC())
        self.setViewControllers([home, favorites, search, settings], animated: true)
    }
    
    private func createNav(with title: String, and image: UIImage?, vc: UIViewController) -> UINavigationController {
        let nav = UINavigationController(rootViewController: vc)
        
        nav.tabBarItem.title = title
        nav.tabBarItem.image = image?.resize(toSize: .init(width: 26, height: 26))
        nav.navigationBar.prefersLargeTitles = false
        
        return nav
    }
    
    
    private func wrappedSettingsView() -> UIViewController {
        let settingsVC = UIHostingController(rootView: SettingsViewWrapper())
        return settingsVC
    }
}

