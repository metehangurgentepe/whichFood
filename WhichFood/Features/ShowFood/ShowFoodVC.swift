//
//  ShowFoodVC.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 12.09.2023.
//

import UIKit

class ShowFoodVC: UIViewController {
    var selectedFoods : [Ingredient] = []
    var selectedCategory : [String] = []
    private let viewModel = ShowFoodViewModel()
    
    let segmentedControl = UISegmentedControl()
    let image = UIImage(named: "food")
    let imageView = UIImageView()
    let cookTimeLabel = UILabel()
    let saveButton = UIButton()
    let recipeLabel = UILabel()
    let ingredientsLabel = UILabel()
    let foodNameLabel = UILabel()
    let activityIndicator = UIActivityIndicatorView(style: .large) // Add a UIActivityIndicatorView
    let alertAction = UIAlertAction(title: "Saved Successfully", style: .default)
    let progressViewContainer = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        design()
        segmentedControl.selectedSegmentIndex = 0
        viewModel.delegate = self
        viewModel.fetchFoodRecipe(foods: selectedFoods, category: selectedCategory)
        if viewModel.isLoading {
            activityIndicator.startAnimating()
        }
    }
    
    @objc func segmentedControlValueChanged() {
        // Handle segmented control value change here
        updateLabelsVisibility()
    }
    
    func setupRefreshButton() {
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshButtonTapped))
        navigationItem.rightBarButtonItem = refreshButton
    }
    
    @objc func refreshButtonTapped() {
        activityIndicator.startAnimating()
        progressViewContainer.isHidden = false
        viewModel.fetchFoodRecipe(foods: selectedFoods, category: selectedCategory)
    }
    
    func design() {
        recipeLabel.isHidden = true
        setupLabel()
        setupSegmentedControl()
        setupPhoto()
        setupIngredientLabel()
        setupFoodName()
        setupCookTimeLabel()
        setupSaveButton()
        setupRefreshButton()
        setupActivityIndicator()
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)
    }

    func updateLabelsVisibility() {
        let selectedIndex = segmentedControl.selectedSegmentIndex
        
        // Show/hide labels based on the segmented control's selection
        recipeLabel.isHidden = selectedIndex != 1
        ingredientsLabel.isHidden = selectedIndex != 0
    }
    
    func setupSaveButton() {
        view.addSubview(saveButton)
        
        saveButton.setTitle("Save Recipe", for: .normal)
        saveButton.backgroundColor = Colors.primary.color
        saveButton.addTarget(self, action: #selector(saveRecipe), for: .touchUpInside)
        saveButton.layer.cornerRadius = 12
        
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            saveButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor,constant: -view.bounds.height * 0.03),
            saveButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            
            saveButton.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.8),
            saveButton.heightAnchor.constraint(equalToConstant: view.bounds.height * 0.07)
        ])
        
        // Add animation to the button
            saveButton.addTarget(self, action: #selector(buttonTapped), for: .touchDown)
            saveButton.addTarget(self, action: #selector(buttonReleased), for: .touchUpInside)
            saveButton.addTarget(self, action: #selector(buttonReleased), for: .touchUpOutside)
    }
    
    @objc func buttonTapped() {
        UIView.animate(withDuration: 0.1) {
            self.saveButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }
    }

    @objc func buttonReleased() {
        UIView.animate(withDuration: 0.1) {
            self.saveButton.transform = .identity
        }
    }
    
    @objc func saveRecipe() {
        Task{
            do {
                try await viewModel.saveRecipe()
                showAlert(title: "Success", message: "Recipe saved successfully", buttonTitle: "OK") {
//                    let homeVC = HomeViewController()
                    self.navigationController?.popToRootViewController(animated: true)
                }
                // alertAction isEnabled özelliğini etkinleştirin
                alertAction.isEnabled = true
            } catch {
                showAlert(title: "Error", message: "Could not saved recipe", buttonTitle: "OK")
            }
        }
    }
    
    func showAlert(title: String, message: String, buttonTitle: String, completionHandler: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: buttonTitle, style: .default) { _ in
            // Eylem düğmesine basıldığında çalışacak kodu burada tanımlayabilirsiniz
            completionHandler?() // completionHandler nil değilse çağırır
        }
        
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
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
    
    func setupLabel() {
        view.addSubview(recipeLabel)
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
    func setupActivityIndicator() {
        view.addSubview(progressViewContainer)
        progressViewContainer.addSubview(activityIndicator)
        progressViewContainer.backgroundColor = .black
        progressViewContainer.translatesAutoresizingMaskIntoConstraints = false
        progressViewContainer.layer.cornerRadius = 12
    
        activityIndicator.color = .white
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        
        NSLayoutConstraint.activate([
                progressViewContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                progressViewContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                progressViewContainer.widthAnchor.constraint(equalToConstant: 75),
                progressViewContainer.heightAnchor.constraint(equalToConstant: 75),
                
                activityIndicator.centerXAnchor.constraint(equalTo: progressViewContainer.centerXAnchor),
                activityIndicator.centerYAnchor.constraint(equalTo: progressViewContainer.centerYAnchor),
            ])
    }
}

extension ShowFoodVC: ShowFoodViewDelegate{
    func didFinish() {
        DispatchQueue.main.async {
            let recipeText = self.viewModel.recipe.joined(separator: "\n")
            let ingredientsText = self.viewModel.ingredients.joined(separator: "\n")
            self.recipeLabel.text = recipeText
            self.ingredientsLabel.text = ingredientsText
            self.foodNameLabel.text = self.viewModel.foodName
            self.cookTimeLabel.text = self.viewModel.cookTime
            self.activityIndicator.stopAnimating() // Stop the activity indicator when data is loaded
            self.progressViewContainer.isHidden = true
        }
    }
    
    func didFail(error: Error) {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating() // Stop the activity indicator in case of an error
            self.progressViewContainer.isHidden = true
            self.showAlert(title: "Error", message: "Error occured", buttonTitle: "Try Again",completionHandler: self.refreshButtonTapped)
        }
    }
}
