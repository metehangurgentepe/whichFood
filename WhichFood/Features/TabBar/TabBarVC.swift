//
//  TabBarVC.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 11.09.2023.
//

import UIKit

class TabBarVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let tabBar = TabBarViewController()
        tabBar.tabBar.backgroundColor = .white
        
        addChild(tabBar)
        view.addSubview(tabBar.view)
        tabBar.didMove(toParent: self)
        
    }

}
