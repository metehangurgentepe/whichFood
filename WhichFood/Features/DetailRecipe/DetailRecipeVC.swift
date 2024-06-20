//
//  DetailRecipeVC.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 16.09.2023.
//

import UIKit
import Kingfisher


protocol DetailRecipeVCDelegate: AnyObject{
    func showDetail(_ recipe: Recipe)
}

class DetailRecipeVC: UIViewController {
    private lazy var segmentedControl : UISegmentedControl = {
        let slider = UISegmentedControl()
        slider.insertSegment(withTitle: LocaleKeys.DetailRecipe.ingredients.rawValue.locale(), at: 0, animated: true)
        slider.insertSegment(withTitle: LocaleKeys.DetailRecipe.recipe.rawValue.locale(), at: 1, animated: true)
        slider.backgroundColor = Colors.secondAccent.color
        slider.selectedSegmentTintColor =  Colors.accent.color
        return slider
    }()
    
    private lazy var image = UIImage(named: "food")
    
    private lazy var imageView = UIImageView()
    
    private lazy var cookTimeLabel = UILabel()
    
    private lazy var recipeLabel : UILabel = {
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
    
    private lazy var foodNameLabel = UILabel()
    private lazy var scrollView = UIScrollView()
    private lazy var errorAlert = UIAlertAction()
    private lazy var favButton = UIBarButtonItem(image: SFSymbols.favorites, style: .plain, target: self, action: #selector(addFav))
    
    var viewModel : DetailRecipeViewModelProtocol?
    var recipe: Recipe?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel?.delegate = self
        viewModel?.load()
        
        design()
    }
    
    
    func design() {
        configureViewController()
       
        recipeLabel.isHidden = true
       
        setupPhoto()
        setupSegmentedControl()
        setupScrollView()
        setupRecipeLabel()
        setupIngredientLabel()
        setupFoodName()
        setupCookTimeLabel()
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)
        updateColorsWhenTraitColor()
        configureFavButton()
        
    }
    
    func configureFavButton() {
        PersistenceManager.isSaved(favorite: self.recipe!) { result in
            switch result {
            case .success(let success):
                if success {
                    self.favButton.image = SFSymbols.selectedFavorites
                    self.favButton.action = #selector(self.removeFav)
                } else {
                    self.favButton.image = SFSymbols.favorites
                    self.favButton.action = #selector(self.addFav)
                }
            case .failure(_):
                break
            }
        }
    }
    
    @objc func addFav() {
        PersistenceManager.updateWith(favorite: self.recipe!, actionType: .add) { error in
//            self.presentAlertOnMainThread(title: LocaleKeys.Error.alert.rawValue.locale(),
//                                     message: error?.localizedDescription ?? "",
//                                     buttonTitle: LocaleKeys.Error.okButton.rawValue.locale())
        }
        configureFavButton()
    }
    
    @objc func removeFav() {
        PersistenceManager.updateWith(favorite: self.recipe!, actionType: .remove) { error in
//            self.presentAlertOnMainThread(title: LocaleKeys.Error.alert.rawValue.locale(),
//                                     message: error?.localizedDescription ?? "",
//                                     buttonTitle: LocaleKeys.Error.okButton.rawValue.locale())
        }
        configureFavButton()
    }
    
    
    @objc func segmentedControlValueChanged() {
        updateLabelsVisibility()
    }
    
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateColorsWhenTraitColor()
    }
    
    
    private func configureViewController() {
        let backButton = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        
        view.backgroundColor = .systemBackground
        segmentedControl.selectedSegmentIndex = 0
        
        navigationItem.rightBarButtonItem = favButton
    }
    
    
    private func updateColorsWhenTraitColor() {
        if traitCollection.userInterfaceStyle == .dark {
            recipeLabel.textColor = .white
            ingredientsLabel.textColor = .white
        } else {
            recipeLabel.textColor = .black
            ingredientsLabel.textColor = .black
        }
    }
}


extension DetailRecipeVC: DetailRecipeVCDelegate {
    func showDetail(_ recipe: Recipe) {
        self.recipe = recipe
        recipeLabel.text = recipe.recipe!.joined(separator: "\n")
        ingredientsLabel.text = recipe.ingredients!.joined(separator: "\n")
        cookTimeLabel.text = recipe.cookTime
        foodNameLabel.text = recipe.name
        
        title = recipe.name
        
        if let imageURL = recipe.imageUrl {
            let url = URL(string: imageURL)
            imageView.kf.setImage(with: url)
        }
    }
}

extension DetailRecipeVC {
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
            scrollView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor,constant: 5),
            scrollView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor,constant: 10),
            scrollView.widthAnchor.constraint(equalToConstant: view.bounds.width),
            scrollView.heightAnchor.constraint(equalToConstant: view.bounds.height * 0.35)
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
        ingredientsLabel.font = Fonts.openSans
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
    
    
    func setupFoodName() {
        foodNameLabel.textColor = .black
        foodNameLabel.textAlignment = .right 
        foodNameLabel.translatesAutoresizingMaskIntoConstraints = false
        foodNameLabel.numberOfLines = 2
        
        foodNameLabel.font = .boldSystemFont(ofSize: FontSize.headline)
        imageView.addSubview(foodNameLabel)

        NSLayoutConstraint.activate([
            foodNameLabel.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -30),
            foodNameLabel.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -5),
            foodNameLabel.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.95)
        ])
    }
    
    
    func setupCookTimeLabel() {
        cookTimeLabel.textColor = .black
        cookTimeLabel.textAlignment = .right
        cookTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        cookTimeLabel.font = .preferredFont(forTextStyle: .subheadline).withSize(17)
       
        imageView.addSubview(cookTimeLabel)

        NSLayoutConstraint.activate([
            cookTimeLabel.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -10),
            cookTimeLabel.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -5),
            cookTimeLabel.widthAnchor.constraint(equalToConstant: view.bounds.width)
        ])
    }
    
    
    func setupSegmentedControl() {
        view.addSubview(segmentedControl)

        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: imageView.bottomAnchor,constant: 2),
//            segmentedControl.centerYAnchor.constraint(equalTo: self.view.centerYAnchor,constant: -view.bounds.height * 0.05),
            segmentedControl.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            
            segmentedControl.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.9 ),
            segmentedControl.heightAnchor.constraint(equalToConstant: view.bounds.width * 0.1)
        ])
    }
    
    func setupPhoto() {
        view.addSubview(imageView)
        
//        let size = CGSize(width: view.bounds.width, height: view.bounds.height * 0.42)
//        let resizableImage = image!.resize(toSize: size)
        
        imageView.image = image
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),      
            imageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            imageView.heightAnchor.constraint(equalToConstant: ScreenSize.width),
            imageView.widthAnchor.constraint(equalToConstant: ScreenSize.width)
        ])
    }
}
