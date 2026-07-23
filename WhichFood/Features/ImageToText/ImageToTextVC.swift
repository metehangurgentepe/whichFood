//
//  ImageToTextVC.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 5.12.2023.
//

import UIKit


class ImageToTextVC: DataLoadingVC {
    private lazy var progressViewContainer : UIView = {
       let view = UIView()
        view.backgroundColor = Colors.accent.color
        return view
    }()
    private lazy var activityIndicator = UIActivityIndicatorView(style: .large)
    private lazy var image = UIImageView()
    private lazy var recipeText : UILabel = {
       let label = UILabel()
        let customFont = Fonts.openSans
        label.font = UIFontMetrics.default.scaledFont(for: customFont!).withSize(20)
        label.textAlignment = .left
        label.numberOfLines = 20
        return label
    }()
    private lazy var ingredientLabel : UILabel = {
        let label = UILabel()
        let customFont = Fonts.openSans
        label.font = UIFontMetrics.default.scaledFont(for: customFont!).withSize(20)
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
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        return label
    }()
    private lazy var foodNameLabel : UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline).withSize(24)
        label.textColor = .label
        label.textAlignment = .right
        label.numberOfLines = 2
        return label
    }()

    private lazy var labelsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .trailing
        stackView.layoutMargins = UIEdgeInsets(top: 16, left: 20, bottom: 8, right: 20)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
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

        // Show loading view before starting the upload
        detailCustomLoadingView()
        hideContentElements()

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

    private func hideContentElements() {
        foodNameLabel.isHidden = true
        cookTimeLabel.isHidden = true
        segmentedControl.isHidden = true
        scrollView.isHidden = true
        recipeText.isHidden = true
        ingredientLabel.isHidden = true
    }

    private func showContentElements() {
        foodNameLabel.isHidden = false
        cookTimeLabel.isHidden = false
        segmentedControl.isHidden = false
        scrollView.isHidden = false
        // Don't show labels here, updateLabelsVisibility() will handle it
        updateLabelsVisibility()
    }
    
    private func configure() {
        self.view.backgroundColor = .systemBackground
        saveButton.isEnabled = false
        updateVisibility()
        setupSaveButton()
        setupImage()
        setupLabelsStackView()
        setupSegmentedControl()
        setupScrollView()
        setupRecipeLabel()
        setupIngredientLabel()
        setupProgressView()
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)
        segmentedControl.selectedSegmentIndex = 0

        // Initially hide all content except image and show info
        hideContentElements()
    }
    
    private func setupScrollView() {
        scrollView.isScrollEnabled = true
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = false

        view.addSubview(scrollView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    
    func setupRecipeLabel() {
        scrollView.addSubview(recipeText)
        recipeText.numberOfLines = 0

        recipeText.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            recipeText.topAnchor.constraint(equalTo: scrollView.topAnchor),
            recipeText.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            recipeText.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            recipeText.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            recipeText.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupFoodNameLabel() {
        view.addSubview(foodNameLabel)

        foodNameLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            foodNameLabel.topAnchor.constraint(equalTo: image.bottomAnchor, constant: 20),
            foodNameLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            foodNameLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            foodNameLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 35)
        ])
    }
    
    private func setupCookTimeLabel() {
        view.addSubview(cookTimeLabel)

        cookTimeLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            cookTimeLabel.topAnchor.constraint(equalTo: foodNameLabel.bottomAnchor, constant: 8),
            cookTimeLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            cookTimeLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            cookTimeLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 25)
        ])
    }
    
    private func setupIngredientLabel() {
        scrollView.addSubview(ingredientLabel)
        ingredientLabel.numberOfLines = 0

        ingredientLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            ingredientLabel.topAnchor.constraint(equalTo: scrollView.topAnchor),
            ingredientLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            ingredientLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            ingredientLabel.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            ingredientLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupSegmentedControl() {
        view.addSubview(segmentedControl)

        segmentedControl.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: labelsStackView.bottomAnchor, constant: 20),
            segmentedControl.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            segmentedControl.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            segmentedControl.heightAnchor.constraint(equalToConstant: 44)
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
        view.addSubview(progressViewContainer)
        progressViewContainer.addSubview(activityIndicator)

        progressViewContainer.backgroundColor = .systemGray
        progressViewContainer.layer.cornerRadius = 12
        progressViewContainer.isHidden = true

        activityIndicator.color = .white
        activityIndicator.style = .large

        progressViewContainer.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            progressViewContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressViewContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            progressViewContainer.widthAnchor.constraint(equalToConstant: 80),
            progressViewContainer.heightAnchor.constraint(equalToConstant: 80),

            activityIndicator.centerXAnchor.constraint(equalTo: progressViewContainer.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: progressViewContainer.centerYAnchor)
        ])
    }

    private func setupImage() {
        view.addSubview(image)

        image.image = takenImage
        image.contentMode = .scaleAspectFit
        image.layer.cornerRadius = 12
        image.clipsToBounds = true
        image.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            image.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            image.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            image.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            image.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            image.heightAnchor.constraint(equalToConstant: 200),
            image.widthAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.8)
        ])
    }
    
    private func updateVisibility(){
        // Use system colors for better compatibility
        progressViewContainer.backgroundColor = .systemBackground
        recipeText.textColor = .label
        ingredientLabel.textColor = .label
        foodNameLabel.textColor = .label
        cookTimeLabel.textColor = .secondaryLabel

        // Update segmented control colors
        segmentedControl.backgroundColor = .secondarySystemBackground
        segmentedControl.selectedSegmentTintColor = Colors.accent.color
    }
}

extension ImageToTextVC: ImageToTextViewModelDelegate{
    func handleViewModelOutput(_ output: ImageToTextViewModeOutput) {
        DispatchQueue.main.async{
            switch output {
            case .setLoading(let isLoading):
                DispatchQueue.main.async{
                    if isLoading {
                        self.detailCustomLoadingView()
                        self.hideContentElements()
                    } else {
                        self.dismissLoadingView()
                    }
                }
                
            case .showError(let error):
                DispatchQueue.main.async {
                    self.dismissLoadingView()
                    self.showContentElements()

                    let alert = UIAlertController(title: LocaleKeys.Error.alert.rawValue.locale(),
                                                message: error.localizedDescription,
                                                preferredStyle: .alert)
                    let okAction = UIAlertAction(title: LocaleKeys.Error.okButton.rawValue.locale(), style: .default)
                    alert.addAction(okAction)
                    self.present(alert, animated: true)
                }
                
            case .showRecipe(let text):
                DispatchQueue.main.async {
                    self.dismissLoadingView()
                    self.recipe = text
                    self.saveButton.isEnabled = true
                    self.segmentedControl.selectedSegmentIndex = 0

                    // Show content and hide info label
                    self.showContentElements()

                    // Set data
                    self.recipeText.text = text.recipe.joined(separator: "\n")
                    self.ingredientLabel.text = text.ingredients.joined(separator: "\n")
                    self.foodNameLabel.text = text.foodName
                    self.cookTimeLabel.text = text.cookTime
                }
                
            case .saved:
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: LocaleKeys.DetailRecipe.savedSuccess.rawValue.locale(),
                                                message: "",
                                                preferredStyle: .alert)
                    let okAction = UIAlertAction(title: LocaleKeys.Error.okButton.rawValue.locale(), style: .default)
                    alert.addAction(okAction)
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    func navigate(to navigationType: NavigationType) {

    }
}

// MARK: - UI Setup Extension
extension ImageToTextVC {
    private func setupLabelsStackView() {
        view.addSubview(labelsStackView)
        labelsStackView.addArrangedSubview(foodNameLabel)
        labelsStackView.addArrangedSubview(cookTimeLabel)

        NSLayoutConstraint.activate([
            labelsStackView.topAnchor.constraint(equalTo: image.bottomAnchor, constant: 0),
            labelsStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            labelsStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
}
