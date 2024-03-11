//
//  AppDelegate.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 11.09.2023.
//

import UIKit
import FirebaseCore
import RevenueCat


@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UIApplication.shared.setMinimumBackgroundFetchInterval(TimeInterval(60*15))
        FirebaseApp.configure()
        Purchases.configure(with: Configuration.Builder(withAPIKey: Constants.RevenueCat.apiKey.rawValue)
            .with(usesStoreKit2IfAvailable: true)
            .build())
        Purchases.shared.delegate = self
        return true
    }
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        
    }
    
    
    func getVendorIdentifier() -> String {
        if let vendorID = UIDevice.current.identifierForVendor?.uuidString {
            return vendorID
        } else {
            let uuid = UUID().uuidString
            return uuid
        }
    }
    
    
    func restart() {
        guard let window = UIApplication.shared.windows.first else {
            return
        }
        
        UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
            let oldState = UIView.areAnimationsEnabled
            UIView.setAnimationsEnabled(false)
            window.rootViewController = SplashScreenVC()
            UIView.setAnimationsEnabled(oldState)
        }, completion: nil)
    }
}

extension AppDelegate: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        print("Modefied")
    }
}

