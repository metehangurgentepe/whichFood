//
//  ImageToTextVC.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 5.12.2023.
//

import UIKit

protocol ImageToTextViewModelDelegate: AnyObject{
    func handleViewModelOutput(_ output: ImageToTextViewModeOutput)
    func navigate(to navigationType: NavigationType)
}

class ImageToTextVC: UIViewController {
    private lazy var progressViewContainer : UIView = {
       let view = UIView()
        view.backgroundColor = Colors.accent.color
        return view
    }()
    private lazy var activityIndicator = UIActivityIndicatorView(style: .large)
    private lazy var image = UIImageView()
    private lazy var recipeText : UILabel = {
       let label = UILabel()
        guard let customFont = UIFont(name: "OpenSans-Regular", size: UIFont.labelFontSize) else {
            fatalError("""
                Failed to load the "CustomFont-Light" font.
                Make sure the font file is included in the project and the font name is spelled correctly.
                """
            )
        }
        label.font = UIFontMetrics.default.scaledFont(for: customFont).withSize(20)
        label.textAlignment = .left
        label.numberOfLines = 20
        return label
    }()
    private lazy var ingredientLabel : UILabel = {
       let label = UILabel()
        guard let customFont = UIFont(name: "OpenSans-Regular", size: UIFont.labelFontSize) else {
            fatalError("""
                Failed to load the "CustomFont-Light" font.
                Make sure the font file is included in the project and the font name is spelled correctly.
                """
            )
        }
        label.font = UIFontMetrics.default.scaledFont(for: customFont).withSize(20)
        label.textAlignment = .left
        label.numberOfLines = 20
        return label
    }()
    private lazy var segmentedControl : UISegmentedControl = {
        let slider = UISegmentedControl()
        slider.insertSegment(withTitle: LocaleKeys.DetailRecipe.ingredients.rawValue.locale(), at: 0, animated: true)
        slider.insertSegment(withTitle: LocaleKeys.DetailRecipe.recipe.rawValue.locale(), at: 1, animated: true)
        slider.backgroundColor = Colors.secondAccent.color
        slider.selectedSegmentTintColor =  Colors.accent.color
        return slider
    }()
    private lazy var cookTimeLabel : UILabel = {
       let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline).withSize(14)
        return label
    }()
    private lazy var foodNameLabel : UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline).withSize(24)
        return label
    }()
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()
    private lazy var infoLabel: UILabel = {
        let label = UILabel()
        label.text = LocaleKeys.ImageToText.info.rawValue.locale()
        label.textColor = .black
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .headline)
        return label
    }()
    private lazy var saveButton = UIBarButtonItem(
        image: SFSymbols.saveButton,
        style: .done,
        target: self,
        action: #selector(saveRecipe)
    )
    private let viewModel = ImageToTextViewModel()
    var takenImage: UIImage?
    var recipe: RecipeResponseModel?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
        configure()
        Task{
           await viewModel.uploadRecipePhoto(image: takenImage!)
        }
        segmentedControl.selectedSegmentIndex = 0
    }
}

extension ImageToTextVC {
    @objc func segmentedControlValueChanged() {
        updateLabelsVisibility()
    }
    
    func updateLabelsVisibility() {
        let selectedIndex = segmentedControl.selectedSegmentIndex
        
        recipeText.isHidden = selectedIndex != 1
        ingredientLabel.isHidden = selectedIndex != 0
    }
    
    private func configure() {
        self.view.backgroundColor = .systemBackground
        saveButton.isEnabled = false
        updateVisibility()
        setupSaveButton()
        setupScrollView()
        setupImage()
        setupRecipeLabel()
        setupFoodNameLabel()
        setupCookTimeLabel()
        setupSegmentedControl()
        setupIngredientLabel()
        setupProgressView()
        setupInfoLabel()
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)
        segmentedControl.selectedSegmentIndex = 0
    }
    
    private func setupScrollView() {
        scrollView.isScrollEnabled = true
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = true
        
        view.addSubview(scrollView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: view.bounds.height * 0.2),
            scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor,constant: 10),
            
            scrollView.widthAnchor.constraint(equalToConstant: view.bounds.width),
            scrollView.heightAnchor.constraint(equalToConstant: view.bounds.height * 0.28)
        ])
    }
    
    private func setupInfoLabel() {
        view.addSubview(infoLabel)
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            infoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            infoLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    
    func setupRecipeLabel() {
        scrollView.addSubview(recipeText)
        recipeText.numberOfLines = 30
        
        recipeText.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            recipeText.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 10),
            recipeText.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            recipeText.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -10),
            recipeText.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -10),
            recipeText.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -10)
        ])
    }
    
    private func setupFoodNameLabel() {
        view.addSubview(foodNameLabel)
        
        foodNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            foodNameLabel.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: view.bounds.height * 0.3),
            foodNameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            foodNameLabel.widthAnchor.constraint(equalToConstant: view.bounds.width),
            foodNameLabel.heightAnchor.constraint(equalToConstant: 35)
            
        ])
    }
    
    private func setupCookTimeLabel() {
        view.addSubview(cookTimeLabel)
        
        cookTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cookTimeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: view.bounds.height * 0.3 + 20),
            cookTimeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor,constant: 20),
            
            cookTimeLabel.widthAnchor.constraint(equalToConstant: view.bounds.width),
            cookTimeLabel.heightAnchor.constraint(equalToConstant: 25),
        ])
    }
    
    private func setupIngredientLabel() {
        scrollView.addSubview(ingredientLabel)
        ingredientLabel.numberOfLines = 30
        
        ingredientLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            ingredientLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 10),
            ingredientLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            ingredientLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -10),
            ingredientLabel.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -10),
            ingredientLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -10)
        ])
    }
    
    private func setupSegmentedControl() {
        view.addSubview(segmentedControl)
        
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            segmentedControl.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            segmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            segmentedControl.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.9),
            segmentedControl.heightAnchor.constraint(equalToConstant: view.bounds.width * 0.1)
        ])
    }
    
    private func setupSaveButton() {
        navigationItem.rightBarButtonItem = saveButton
    }
    
    
    @objc func saveRecipe() {
        Task{
           await viewModel.saveRecipe(recipe: recipe)
        }
    }
    
    private func setupProgressView() {
        progressViewContainer.backgroundColor = .red
        view.addSubview(progressViewContainer)
        progressViewContainer.addSubview(activityIndicator) // Add activityIndicator as a subview
        progressViewContainer.backgroundColor = .black
        progressViewContainer.layer.cornerRadius = 12
        progressViewContainer.isHidden = true
        activityIndicator.color = .white

        progressViewContainer.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            progressViewContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressViewContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            progressViewContainer.widthAnchor.constraint(equalToConstant: 75),
            progressViewContainer.heightAnchor.constraint(equalToConstant: 75),

            // Constraints for activityIndicator
            activityIndicator.centerXAnchor.constraint(equalTo: progressViewContainer.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: progressViewContainer.centerYAnchor),
        ])
    }

    private func setupImage() {
        view.addSubview(image)
        
        image.image = takenImage
        image.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            image.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,constant: 20),
            image.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            image.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.5),
            image.heightAnchor.constraint(equalToConstant: view.bounds.height * 0.25),
        ])
    }
    
    private func updateVisibility(){
        if traitCollection.userInterfaceStyle == .light {
            progressViewContainer.backgroundColor = .black
            recipeText.textColor = .black
            ingredientLabel.textColor = .black
            foodNameLabel.textColor = .black
            cookTimeLabel.textColor = .black
        } else {
            progressViewContainer.backgroundColor = .white
            recipeText.textColor = .white
            ingredientLabel.textColor = .white
            foodNameLabel.textColor = .white
            cookTimeLabel.textColor = .white
        }
    }
}

extension ImageToTextVC: ImageToTextViewModelDelegate{
    func handleViewModelOutput(_ output: ImageToTextViewModeOutput) {
        DispatchQueue.main.async{
            switch output {
            case .setLoading(let isLoading):
                DispatchQueue.main.async{
                    if isLoading {
                        self.activityIndicator.isHidden = false
                        self.progressViewContainer.isHidden = false
                        self.activityIndicator.startAnimating()
                    } else {
                        self.activityIndicator.isHidden = true
                        self.progressViewContainer.isHidden = true
                        self.activityIndicator.stopAnimating()
                    }
                }
            case .showError(let error):
                let alert = showAlert(title: LocaleKeys.Error.alert.rawValue.locale(),
                                      message: error.localizedDescription,
                                      buttonTitle: LocaleKeys.Error.okButton.rawValue.locale(), secondButtonTitle: nil)
                self.present(alert, animated: true)
            case .showRecipe(let text):
                DispatchQueue.main.async {
                    self.recipe = text
                    self.saveButton.isEnabled = true
                    self.segmentedControl.selectedSegmentIndex = 0
                    self.recipeText.isHidden = true
                    self.recipeText.text = text.recipe.joined(separator: ", ")
                    self.ingredientLabel.text = text.ingredients.joined(separator: ", ")
                    self.foodNameLabel.text = text.foodName
                    self.cookTimeLabel.text = text.cookTime
                }
            case .saved:
                let alert = showAlert(title: LocaleKeys.DetailRecipe.savedSuccess.rawValue.locale(),
                                      message: "",
                                      buttonTitle: LocaleKeys.Error.okButton.rawValue.locale(), secondButtonTitle: nil)
                self.present(alert, animated: true)
            }
        }
    }
    
    func navigate(to navigationType: NavigationType) {
        
    }
}
