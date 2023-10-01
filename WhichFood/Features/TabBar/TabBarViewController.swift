//
//  TabBarViewController.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 11.09.2023.
//

import UIKit

class TabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // İlk sekme için bir ViewController oluşturun
          let firstViewController = HomeViewController()
           //firstViewController.view.backgroundColor = UIColor.red
          firstViewController.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), selectedImage: nil)

          // İkinci sekme için bir ViewController oluşturun
          let secondViewController = PlanFoodViewController()
          //secondViewController.view.backgroundColor = UIColor.blue
          secondViewController.tabBarItem = UITabBarItem(title: "Restaurants", image: UIImage(systemName: "bell"), selectedImage: nil)
        
            let thirdViewController = NotesViewController()
            thirdViewController.tabBarItem = UITabBarItem(title: "Notes", image: UIImage(systemName: "note.text"), selectedImage: nil)


          // TabBarController'a sekme görünümlerini ekleyin
          viewControllers = [firstViewController, secondViewController,thirdViewController]
    }

}
