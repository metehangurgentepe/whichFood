//
//  TabBarController.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 3.12.2023.
//

import Foundation
import UIKit
import SwiftUI

struct SettingsViewWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let settingsVC = UIHostingController(rootView: SettingsView())
        return settingsVC
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}


class MainTabBarController: UITabBarController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let premiumVC = PremiumVC()
        premiumVC.modalPresentationStyle = .overFullScreen
        present(premiumVC, animated: true, completion: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupTabs()
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
            and: SFSymbols.home,
            vc: HomeViewController())
        let search = self.createNav(
            with: LocaleKeys.Home.search.rawValue.locale(),
            and: SFSymbols.search,
            vc: SearchViewController())
        let favorites = self.createNav(
            with: LocaleKeys.Home.favorites.rawValue.locale(),
            and: SFSymbols.favorites,
            vc: FavoriteViewController())
        let settings = self.createNav(
            with: LocaleKeys.Settings.title.rawValue.locale(),
            and: SFSymbols.settings,
            vc: SettingsVC())
        self.setViewControllers([home, favorites, search, settings], animated: true)
    }
    
    private func createNav(with title: String, and image: UIImage?, vc: UIViewController) -> UINavigationController {
        let nav = UINavigationController(rootViewController: vc)
        
        nav.tabBarItem.title = title
        nav.tabBarItem.image = image
        nav.navigationBar.prefersLargeTitles = false
        
        switch title {
        case LocaleKeys.Home.recipe.rawValue.locale():
            nav.tabBarItem.selectedImage = SFSymbols.selectedHome?.withRenderingMode(.alwaysTemplate)
        case LocaleKeys.Home.search.rawValue.locale():
            nav.tabBarItem.selectedImage = SFSymbols.selectedSearch?.withRenderingMode(.alwaysTemplate)
        case LocaleKeys.Home.favorites.rawValue.locale():
            nav.tabBarItem.selectedImage = SFSymbols.selectedFavorites?.withRenderingMode(.alwaysTemplate)
        case LocaleKeys.Settings.title.rawValue.locale():
            nav.tabBarItem.selectedImage = SFSymbols.selectedSettings?.withRenderingMode(.alwaysTemplate)
        default:
            nav.tabBarItem.selectedImage = image?.withRenderingMode(.alwaysTemplate)
        }
        
        return nav
    }
    
    
    private func wrappedSettingsView() -> UIViewController {
        let settingsVC = UIHostingController(rootView: SettingsViewWrapper())
        return settingsVC
    }
}
