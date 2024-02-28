//
//  ShowFoodVC.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 12.09.2023.
//

import UIKit

protocol ShowFoodViewDelegate: AnyObject {
    func handleViewModelOutput(_ output: ShowFoodViewModelOutput)
}

class ShowFoodVC: UIViewController {
    var selectedFoods : [Ingredient] = []
    var selectedCategory : [String] = []
    private lazy var image = UIImage(named: "recipe_background")
    private lazy var imageView = UIImageView()
    private lazy var cookTimeLabel = UILabel()
    private lazy var saveButton = UIButton()
    private lazy var foodNameLabel = UILabel()
    private lazy var activityIndicator = UIActivityIndicatorView(style: .large)
    private lazy var alertAction = UIAlertAction(title: LocaleKeys.DetailRecipe.savedSuccess.rawValue.locale(), style: .default)
    private lazy var progressViewContainer = UIView()
    private var refreshButton = UIBarButtonItem()
    private lazy var segmentedControl : UISegmentedControl = {
        let slider = UISegmentedControl()
        slider.insertSegment(withTitle: LocaleKeys.DetailRecipe.ingredients.rawValue.locale(), at: 0, animated: true)
        slider.insertSegment(withTitle: LocaleKeys.DetailRecipe.recipe.rawValue.locale(), at: 1, animated: true)
        slider.backgroundColor = Colors.secondAccent.color
        slider.selectedSegmentTintColor =  Colors.accent.color
        return slider
    }()
    private lazy var recipeLabel: UILabel = {
        let label = UILabel()
        guard let customFont = UIFont(name: "OpenSans-Regular", size: UIFont.labelFontSize) else {
            fatalError("""
                Failed to load the "CustomFont-Light" font.
                Make sure the font file is included in the project and the font name is spelled correctly.
                """
            )
        }
        label.font = UIFontMetrics.default.scaledFont(for: customFont).withSize(15)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    private lazy var ingredientsLabel : UILabel = {
        let label = UILabel()
        guard let customFont = UIFont(name: "OpenSans-Regular", size: UIFont.labelFontSize) else {
            fatalError("""
                Failed to load the "CustomFont-Light" font.
                Make sure the font file is included in the project and the font name is spelled correctly.
                """
            )
        }
        label.font = UIFontMetrics.default.scaledFont(for: customFont).withSize(15)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()
    private let viewModel = ShowFoodViewModel()
    var recipe: RecipeResponseModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        design()
        segmentedControl.selectedSegmentIndex = 0
        viewModel.delegate = self
        viewModel.fetchFoodRecipe(foods: selectedFoods, category: selectedCategory)
        updateColorsWhenTraitColor()
    }
    
    @objc func segmentedControlValueChanged() {
        updateLabelsVisibility()
    }
    
    @objc func refreshButtonTapped() {
        activityIndicator.startAnimating()
        progressViewContainer.isHidden = false
        Task{
           try await viewModel.increaseUsageApi()
        }
        viewModel.fetchFoodRecipe(foods: selectedFoods, category: selectedCategory)
    }
    
    func design() {
        setupScrollView()
        recipeLabel.isHidden = true
        setupRecipeLabel()
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
    
    @objc func saveRecipe() {
        Task{
            viewModel.saveRecipe(recipe!)
            let alert = showAlert(title: LocaleKeys.DetailRecipe.success.rawValue.locale(),
                                  message: LocaleKeys.DetailRecipe.savedSuccess.rawValue.locale(),
                                  buttonTitle: LocaleKeys.DetailRecipe.okButton.rawValue.locale(), secondButtonTitle: nil, completionHandler:  {
                self.navigationController?.popToRootViewController(animated: true)
            })
            self.present(alert, animated: true)
            alertAction.isEnabled = true
        }
    }
    
    private func backButton() {
        let home = HomeViewController()
        self.navigationController?.popToViewController(home, animated: true)
    }
    
}
// MARK: ShowFood delegate
extension ShowFoodVC: ShowFoodViewDelegate{
    func handleViewModelOutput(_ output: ShowFoodViewModelOutput) {
        switch output {
        case .setLoading(let isLoading):
            DispatchQueue.main.async {
                if isLoading{
                    self.activityIndicator.startAnimating()
                    self.progressViewContainer.isHidden = false
                    self.saveButton.isEnabled = false
                    self.refreshButton.isEnabled = false
                } else {
                    self.activityIndicator.stopAnimating()
                    self.progressViewContainer.isHidden = true
                    self.saveButton.isEnabled = true
                    self.refreshButton.isEnabled = true
                }
            }
        case .showRecipe(let recipe):
            self.recipe = recipe
            cookTimeLabel.text = recipe.cookTime
            foodNameLabel.text = recipe.foodName
            ingredientsLabel.text = recipe.ingredients.joined(separator: "\n")
            recipeLabel.text = recipe.recipe.joined(separator: "\n")
        case .showError(let error):
            DispatchQueue.main.async{
                var alert = UIAlertController()
                switch error {
                case ApiUsageError.exceededApiLimit:
                    alert = showAlert(
                        title: LocaleKeys.DetailRecipe.error.rawValue.locale(),
                        message: LocaleKeys.Error.apiUsageError.rawValue.locale(),
                        buttonTitle:LocaleKeys.Error.okButton.rawValue.locale() ,
                        secondButtonTitle: LocaleKeys.Error.backButton.rawValue.locale(),
                        completionHandler: self.backButton,
                        completionSecondHandler: self.backButton
                    )
                default:
                    alert = showAlert(
                        title: LocaleKeys.DetailRecipe.error.rawValue.locale(),
                        message: LocaleKeys.DetailRecipe.errorOccured.rawValue.locale(),
                        buttonTitle: LocaleKeys.DetailRecipe.tryAgain.rawValue.locale(),
                        secondButtonTitle: LocaleKeys.Error.backButton.rawValue.locale(),
                        completionHandler: self.refreshButtonTapped,
                        completionSecondHandler: self.backButton)
                }
                self.activityIndicator.stopAnimating()
                self.progressViewContainer.isHidden = true
                self.present(alert, animated: true)
            }
        case .saveRecipe:
            viewModel.saveRecipe(recipe)
        }
    }
}
// MARK: ShwoFood design extension
extension ShowFoodVC {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateColorsWhenTraitColor()
    }
    
    func setupRefreshButton() {
        refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshButtonTapped))
        navigationItem.rightBarButtonItem = refreshButton
    }
    
    private func updateColorsWhenTraitColor() {
        if traitCollection.userInterfaceStyle == .dark {
            progressViewContainer.backgroundColor = .white
            activityIndicator.color = .black
        } else {
            progressViewContainer.backgroundColor = .black
            activityIndicator.color = .white
        }
    }
    
    func updateLabelsVisibility() {
        let selectedIndex = segmentedControl.selectedSegmentIndex
        
        recipeLabel.isHidden = selectedIndex != 1
        ingredientsLabel.isHidden = selectedIndex != 0
    }
    
    func setupScrollView() {
        scrollView.isScrollEnabled = true
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = true
        
        view.addSubview(scrollView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor,constant: -view.bounds.height * 0.15),
            scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor,constant: 10),
            
            scrollView.widthAnchor.constraint(equalToConstant: view.bounds.width),
            scrollView.heightAnchor.constraint(equalToConstant: view.bounds.height * 0.35)
        ])
    }
    
    func setupSaveButton() {
        view.addSubview(saveButton)
        
        saveButton.setTitle(NSLocalizedString(LocaleKeys.DetailRecipe.saveButton.rawValue, comment: "Save Recipe"), for: .normal)
        saveButton.backgroundColor = Colors.primary.color
        saveButton.addTarget(self, action: #selector(saveRecipe), for: .touchUpInside)
        saveButton.layer.cornerRadius = 12
        
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            saveButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor,constant: -view.bounds.height * 0.05),
            saveButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            
            saveButton.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.8),
            saveButton.heightAnchor.constraint(equalToConstant: view.bounds.height * 0.07)
        ])
    }
    
    func setupFoodName() {
        foodNameLabel.textColor = .white
        foodNameLabel.textAlignment = .right // Sağa hizalı
        foodNameLabel.translatesAutoresizingMaskIntoConstraints = false
        foodNameLabel.numberOfLines = 2
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
        
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            segmentedControl.centerYAnchor.constraint(equalTo: self.view.centerYAnchor,constant: -view.bounds.height * 0.05),
            segmentedControl.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            
            segmentedControl.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.9),
            segmentedControl.heightAnchor.constraint(equalToConstant: view.bounds.width * 0.1)
        ])
    }
    
    func setupRecipeLabel() {
        scrollView.addSubview(recipeLabel)
        recipeLabel.numberOfLines = 30
        
        recipeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            recipeLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 10),
            recipeLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            recipeLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -10),
            recipeLabel.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -10),
            recipeLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -10)
        ])
    }
    
    func setupIngredientLabel() {
        guard let customFont = UIFont(name: "OpenSans-Regular", size: UIFont.labelFontSize) else {
            fatalError("""
                Failed to load the "CustomFont-Light" font.
                Make sure the font file is included in the project and the font name is spelled correctly.
                """
            )
        }
        ingredientsLabel.font = UIFontMetrics.default.scaledFont(for: customFont)
        ingredientsLabel.adjustsFontForContentSizeCategory = true
        
        scrollView.addSubview(ingredientsLabel)
        ingredientsLabel.numberOfLines = 30
        
        ingredientsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            ingredientsLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 10),
            ingredientsLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            ingredientsLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -10),
            ingredientsLabel.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -10),
            ingredientsLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -10)
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
    
    func setupPhoto() {
        view.addSubview(imageView)
        
        let size = CGSize(width: view.bounds.width, height: view.bounds.height * 0.42)
        let resizableImage = image!.resize(toSize: size)
        imageView.layer.cornerRadius = 12
        imageView.image = resizableImage
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            imageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            
            imageView.heightAnchor.constraint(equalToConstant: view.bounds.height * 0.3),
            
        ])
    }
    
}
