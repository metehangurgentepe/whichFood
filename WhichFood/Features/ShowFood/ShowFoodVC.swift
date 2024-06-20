//
//  ShowFoodVC.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 12.09.2023.
//

import UIKit
import Kingfisher

protocol ShowFoodViewDelegate: AnyObject {
    func handleViewModelOutput(_ output: ShowFoodViewModelOutput)
}

class ShowFoodVC: DataLoadingVC {
    var selectedFoods : [Ingredient] = []
    var selectedCategory : [String] = []
    private lazy var image = UIImage(named: "recipe_background")
    
    var imageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 10
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var cookTimeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton()
        button.setTitle(NSLocalizedString(LocaleKeys.DetailRecipe.saveButton.rawValue, comment: "Save Recipe"), for: .normal)
        button.backgroundColor = Colors.primary.color
        button.addTarget(self, action: #selector(saveRecipe), for: .touchUpInside)
        button.layer.cornerRadius = 12
        return button
    }()
    
    private lazy var foodNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 2
        label.font = .preferredFont(forTextStyle: .headline).withSize(22)
        return label
    }()
    
    private lazy var alertAction = UIAlertAction(title: LocaleKeys.DetailRecipe.savedSuccess.rawValue.locale(), style: .default)
    
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
        let customFont = Fonts.openSans
        label.font = UIFontMetrics.default.scaledFont(for: customFont!).withSize(15)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 30
        return label
    }()
    
    private lazy var ingredientsLabel : UILabel = {
        let label = UILabel()
        let customFont = Fonts.openSans
        label.font = UIFontMetrics.default.scaledFont(for: customFont!).withSize(15)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 30
        return label
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.isScrollEnabled = true
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = true
        return scrollView
    }()
    
    private lazy var indicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.style = .large
        indicator.color = Colors.primary.color
        return indicator
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
    }
    
    
    @objc func segmentedControlValueChanged() {
        updateLabelsVisibility()
    }
    
    
    @objc func refreshButtonTapped() {
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
        setupIndicator()
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)
    }
    
    
    @objc func saveRecipe() {
        viewModel.saveRecipe(recipe!)
    }
    
    
    private func backButton() {
        let home = HomeViewController()
        self.navigationController?.popToViewController(home, animated: true)
    }
    
}
// MARK: ShowFood delegate
extension ShowFoodVC: ShowFoodViewDelegate{
    func handleViewModelOutput(_ output: ShowFoodViewModelOutput) {
        DispatchQueue.main.async{ [weak self ] in
            guard let self = self else { return }
            switch output {
            case .setLoading(let isLoading):
                DispatchQueue.main.async {
                    if isLoading{
                        self.customLoadingView()
                    } else {
                        self.dismissLoadingView()
                    }
                }
                
            case .showRecipe(let recipe):
                self.recipe = recipe
                cookTimeLabel.text = recipe.cookTime
                foodNameLabel.text = recipe.foodName
                ingredientsLabel.text = recipe.ingredients.joined(separator: "\n")
                recipeLabel.text = recipe.recipe.joined(separator: "\n")
                
            case .showError(let error):
                presentAlertOnMainThread(
                    title: LocaleKeys.Error.alert.rawValue.locale(),
                    message: error.localizedDescription,
                    buttonTitle: LocaleKeys.Error.okButton.rawValue.locale())
                
            case .saveRecipe:
                viewModel.saveRecipe(recipe)
                
            case .showImage(let url):
                let imageURL = URL(string: url)
                let processor = DownsamplingImageProcessor(size: imageView.bounds.size)
                |> RoundCornerImageProcessor(cornerRadius: 10)
                self.imageView.kf.setImage(
                    with: imageURL,
                    placeholder: Images.background,
                    options: [
                        .processor(processor),
                        .scaleFactor(UIScreen.main.scale),
                        .transition(.fade(1)),
                        .cacheOriginalImage
                    ])
                
            case .successSave(let success):
                if success{
                    let alert = showAlert(title: LocaleKeys.DetailRecipe.success.rawValue.locale(),
                                          message: LocaleKeys.DetailRecipe.savedSuccess.rawValue.locale(),
                                          buttonTitle: LocaleKeys.DetailRecipe.okButton.rawValue.locale(), secondButtonTitle: nil, completionHandler:  {
                        self.navigationController?.popToRootViewController(animated: true)
                    })
                    self.present(alert, animated: true)
                    alertAction.isEnabled = true
                }
            case .loadingImage(let isLoading):
                if isLoading{
                    indicator.startAnimating()
                    imageView.isHidden = true
                } else {
                    indicator.stopAnimating()
                    imageView.isHidden = false
                }
            }
        }
    }
}

// MARK: ShwoFood design extension
extension ShowFoodVC {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
    }
    
    func setupRefreshButton() {
        refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshButtonTapped))
        navigationItem.rightBarButtonItem = refreshButton
    }
    
    func updateLabelsVisibility() {
        let selectedIndex = segmentedControl.selectedSegmentIndex
        
        recipeLabel.isHidden = selectedIndex != 1
        ingredientsLabel.isHidden = selectedIndex != 0
    }
    
    func setupScrollView() {
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
        
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            saveButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor,constant: -view.bounds.height * 0.05),
            saveButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.8),
            saveButton.heightAnchor.constraint(equalToConstant: view.bounds.height * 0.07)
        ])
    }
    
    func setupFoodName() {
        imageView.addSubview(foodNameLabel)
        
        NSLayoutConstraint.activate([
            foodNameLabel.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -30),
            foodNameLabel.centerXAnchor.constraint(equalTo: imageView.centerXAnchor, constant: -10),
            foodNameLabel.widthAnchor.constraint(equalToConstant: view.bounds.width)
        ])
    }
    
    func setupCookTimeLabel() {
        imageView.addSubview(cookTimeLabel)
        
        NSLayoutConstraint.activate([
            cookTimeLabel.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -10),
            cookTimeLabel.centerXAnchor.constraint(equalTo: imageView.centerXAnchor, constant: -10),
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
        scrollView.addSubview(ingredientsLabel)
        
        ingredientsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            ingredientsLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 10),
            ingredientsLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            ingredientsLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -10),
            ingredientsLabel.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -10),
            ingredientsLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -10)
        ])
    }
    
    func setupPhoto() {
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let size = CGSize(width: view.bounds.width, height: view.bounds.height * 0.42)
        let resizableImage = image!.resize(toSize: size)
        imageView.image = resizableImage
        
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: view.bounds.height * 0.3)
        ])
    }
    
    func setupIndicator() {
        view.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            indicator.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            indicator.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
        ])
    }
}
