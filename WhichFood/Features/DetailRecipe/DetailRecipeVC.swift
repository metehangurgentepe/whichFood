//
//  DetailRecipeVC.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 16.09.2023.
//

import UIKit

class DetailRecipeVC: UIViewController {
    var recipe: Recipe?
    let segmentedControl = UISegmentedControl()
    let image = UIImage(named: "food")
    let imageView = UIImageView()
    let cookTimeLabel = UILabel()
    let recipeLabel = UILabel()
    let ingredientsLabel = UILabel()
    let foodNameLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        design()
        segmentedControl.selectedSegmentIndex = 0
        
    }
    func design() {
        recipeLabel.isHidden = true
        setupLabel()
        setupSegmentedControl()
        setupPhoto()
        setupIngredientLabel()
        setupFoodName()
        setupCookTimeLabel()
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)
    }
    @objc func segmentedControlValueChanged() {
        // Handle segmented control value change here
        updateLabelsVisibility()
    }
    func updateLabelsVisibility() {
        let selectedIndex = segmentedControl.selectedSegmentIndex
        
        // Show/hide labels based on the segmented control's selection
        recipeLabel.isHidden = selectedIndex != 1
        ingredientsLabel.isHidden = selectedIndex != 0
    }
    
    func setupLabel() {
        view.addSubview(recipeLabel)
        recipeLabel.text = recipe?.recipe.joined(separator: ", ")
        recipeLabel.textColor = .black
        recipeLabel.font = UIFont.systemFont(ofSize: 16)
        recipeLabel.numberOfLines = 30
        
        recipeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            recipeLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor,constant: view.bounds.height * 0.2),
            recipeLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor,constant: 10),
            
            recipeLabel.widthAnchor.constraint(equalToConstant: view.bounds.width),
            recipeLabel.heightAnchor.constraint(equalToConstant: view.bounds.height)
        ])
    }
    
    func setupIngredientLabel() {
        view.addSubview(ingredientsLabel)
        ingredientsLabel.text = recipe?.ingredients.joined(separator: ", ")
        ingredientsLabel.textColor = .black
        ingredientsLabel.font = .preferredFont(forTextStyle: .title3)
        ingredientsLabel.numberOfLines = 30
        
        
        ingredientsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            ingredientsLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor,constant: view.bounds.height * 0.2),
            ingredientsLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor,constant: 10),
            
            ingredientsLabel.widthAnchor.constraint(equalToConstant: view.bounds.width),
            ingredientsLabel.heightAnchor.constraint(equalToConstant: view.bounds.height)
        ])
    }
    
    func setupSegmentedControl() {
        view.addSubview(segmentedControl)
       
        segmentedControl.insertSegment(withTitle: "Malzemeler", at: 0, animated: true)
        segmentedControl.insertSegment(withTitle: "Yapılışı", at: 1, animated: true)

        segmentedControl.translatesAutoresizingMaskIntoConstraints = false

        
        NSLayoutConstraint.activate([
            segmentedControl.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            segmentedControl.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            
            segmentedControl.widthAnchor.constraint(equalToConstant: view.bounds.width ),
            segmentedControl.heightAnchor.constraint(equalToConstant: view.bounds.width * 0.1)
        ])
    }
    
    func setupPhoto() {
        view.addSubview(imageView)
        
        let capInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        let resizableImage = image!.resizableImage(withCapInsets: capInsets)
        
        imageView.image = resizableImage
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: self.view.topAnchor,constant: 150),
            imageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            
            imageView.heightAnchor.constraint(equalToConstant: view.bounds.height * 0.3),
            
        ])
    }
    
    func setupFoodName() {
        foodNameLabel.text = recipe?.name
        foodNameLabel.textColor = .white
        foodNameLabel.textAlignment = .right // Sağa hizalı
        foodNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        foodNameLabel.font = .preferredFont(forTextStyle: .title2)
        imageView.addSubview(foodNameLabel)

        NSLayoutConstraint.activate([
            foodNameLabel.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -30), // 10 piksel yukarıdan
            foodNameLabel.centerXAnchor.constraint(equalTo: imageView.centerXAnchor, constant: -10), // 10 piksel soldan
            
            foodNameLabel.widthAnchor.constraint(equalToConstant: view.bounds.width)
        ])
    }
    
    func setupCookTimeLabel() {
        cookTimeLabel.text = recipe?.cookTime
        cookTimeLabel.textColor = .white
        cookTimeLabel.textAlignment = .right // Sağa hizalı
        cookTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        cookTimeLabel.font = .preferredFont(forTextStyle: .headline)
       
        imageView.addSubview(cookTimeLabel)

        NSLayoutConstraint.activate([
            cookTimeLabel.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -10), // 10 piksel yukarıdan
            cookTimeLabel.centerXAnchor.constraint(equalTo: imageView.centerXAnchor, constant: -10), // 10 piksel soldan
            
            cookTimeLabel.widthAnchor.constraint(equalToConstant: view.bounds.width)
        ])
    }
}
