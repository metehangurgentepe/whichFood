//
//  DiscoverFoodVC.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 1.03.2024.
//

import UIKit
import GoogleGenerativeAI
import SDWebImage
import Kingfisher


class DiscoverFoodVC: DataLoadingVC {
    let label: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = .preferredFont(forTextStyle: .body)
        label.numberOfLines = 20
        return label
    }()
    
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
        label.font = .preferredFont(forTextStyle: .headline).withSize(22)
        return label
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
        return label
    }()
    private lazy var ingredientsLabel : UILabel = {
        let label = UILabel()
        let customFont = Fonts.openSans
        label.font = UIFontMetrics.default.scaledFont(for: customFont!).withSize(15)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()
    
    private lazy var indicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.style = .large
        indicator.color = Colors.primary.color
        return indicator
    }()
    
    let jsonString = """
        {
          "foodName": "",
          "ingredients": [
            "",
          ],
          "recipe": [
            ""
          ],
          "cookTime": "",
          "description": "",
            "type:": ""
        }
        """
    
    var text: String?
    var recipe: RecipeResponseModel?
    var viewModel = DiscoverFoodViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .systemBackground
        design()
        viewModel.delegate = self
        viewModel.postInput()
    }
    
    func design() {
        configureBarButton()
        configureImage()
        setupSegmentedControl()
        setupScrollView()
        recipeLabel.isHidden = true
        setupRecipeLabel()
        setupIngredientLabel()
        setupFoodName()
        setupCookTimeLabel()
        setupIndicator()
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)
        segmentedControl.selectedSegmentIndex = 0
    }
    
    
    func configureBarButton() {
        let image = SFSymbols.saveButton
        let saveButton = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(saveButton))
        navigationItem.rightBarButtonItem = saveButton
    }
    
    
    @objc func saveButton() {
        viewModel.delegate?.handleViewModelOutput(.saveRecipe)
    }
    
    
    @objc func segmentedControlValueChanged() {
        updateLabelsVisibility()
    }
    
    
    func updateLabelsVisibility() {
        let selectedIndex = segmentedControl.selectedSegmentIndex
        
        recipeLabel.isHidden = selectedIndex != 1
        ingredientsLabel.isHidden = selectedIndex != 0
    }
    
    
    private func configureLabel() {
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor,constant: -20),
        ])
        
    }
}

extension DiscoverFoodVC {
    private func configureImage() {
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.image = Images.recipeBackground
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: view.bounds.height * 0.3)
        ])
    }
    
    
    func setupScrollView() {
        scrollView.isScrollEnabled = true
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = true
        
        view.addSubview(scrollView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor),
            scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor,constant: -view.bounds.height * 0.15),
            scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor,constant: 10),
            scrollView.widthAnchor.constraint(equalToConstant: view.bounds.width),
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
            segmentedControl.topAnchor.constraint(equalTo: imageView.bottomAnchor,constant: 5),
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
        let customFont = UIFont(name: "OpenSans-Regular", size: UIFont.labelFontSize)
        ingredientsLabel.font = UIFontMetrics.default.scaledFont(for: customFont!)
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
    
    func setupIndicator() {
        view.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            indicator.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            indicator.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
        ])
    }
}

extension DiscoverFoodVC: DiscoverFoodViewDelegate {
    func handleViewModelOutput(_ output: DiscoverFoodViewModelOutput) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch output {
            case .setLoading(let isLoading):
                DispatchQueue.main.async{
                    if isLoading {
                        self.customLoadingView()
                    } else {
                        self.dismissLoadingView()
                    }
                }
                
            case .showRecipe(let recipe):
                self.recipe = recipe
                self.cookTimeLabel.text = recipe.cookTime
                self.foodNameLabel.text = recipe.foodName
                self.ingredientsLabel.text = recipe.ingredients.joined(separator: "\n")
                self.recipeLabel.text = recipe.recipe.joined(separator: "\n")
                
            case .showError(let error):
                presentAlertOnMainThread(title: LocaleKeys.Error.alert.rawValue.locale(), message: error.localizedDescription, buttonTitle: LocaleKeys.Error.okButton.rawValue.locale())
                
            case .saveRecipe:
                viewModel.saveRecipe(self.recipe)
                
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
                
            case .loadingPhoto(let isLoading):
                if isLoading{
                    indicator.startAnimating()
                    imageView.isHidden = true
                } else {
                    indicator.stopAnimating()
                    imageView.isHidden = false
                }
            case .successSave:
                let alert = WhichFood.showAlert(title: LocaleKeys.DetailRecipe.success.rawValue.locale(),
                                      message: LocaleKeys.DetailRecipe.savedSuccess.rawValue.locale(),
                                      buttonTitle: LocaleKeys.DetailRecipe.okButton.rawValue.locale(), secondButtonTitle: nil, completionHandler:  {
                    self.navigationController?.popToRootViewController(animated: true)
                })
                self.present(alert, animated: true)
            }
        }
    }
}
