//
//  TabBarController.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 3.12.2023.
//

import Foundation
import UIKit


class MainTabBarController: UITabBarController {
    override func viewDidLoad() {   
        super.viewDidLoad()
        
        self.setupTabs()
        navigationItem.hidesBackButton = true
        
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
        let settings = self.createNav(
            with: LocaleKeys.Settings.title.rawValue.locale(),
            and: SFSymbols.settings,
            vc: SettingsVC())
        self.setViewControllers([home,settings], animated: true)
    }
    
    
    private func createNav(with title: String, and image: UIImage?, vc: UIViewController) -> UINavigationController {
        let nav = UINavigationController(rootViewController: vc)
        
        nav.tabBarItem.title = title
        nav.tabBarItem.image = image
        nav.navigationBar.prefersLargeTitles = false
        
        return nav
    }
}
