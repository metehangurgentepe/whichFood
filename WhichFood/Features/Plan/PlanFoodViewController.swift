//
//  PlanFoodViewController.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 11.09.2023.
//

import UIKit

class PlanFoodViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .cyan
        title = "Plan food"
        navigationController?.navigationBar.prefersLargeTitles = true


        // Do any additional setup after loading the view.
        let label = UILabel()
        label.text = "Plan food"
        label.textColor = .black
        label.frame = CGRect(x: 100, y: 300, width: 200, height: 40) // Set the frame
        view.addSubview(label)
    }

}
