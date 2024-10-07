//
//  ShowFoodVC.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 12.09.2023.
//

import UIKit
import Kingfisher

class ShowFoodVC: DataLoadingVC, UICollectionViewDelegateFlowLayout, MenuControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
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
    
    var collectionView: UICollectionView!
    
    private lazy var alertAction = UIAlertAction(title: LocaleKeys.DetailRecipe.savedSuccess.rawValue.locale(), style: .default)
    
    private var refreshButton = UIBarButtonItem()
    
    private lazy var indicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.style = .large
        indicator.color = Colors.primary.color
        return indicator
    }()
    
    let menuController = MenuController(collectionViewLayout: UICollectionViewFlowLayout())
    
    private let viewModel = ShowFoodViewModel()
    var recipe: RecipeResponseModel?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        design()
        viewModel.delegate = self
        viewModel.fetchFoodRecipe(foods: selectedFoods, category: selectedCategory)
    }
    
    
    @objc func refreshButtonTapped() {
        viewModel.fetchFoodRecipe(foods: selectedFoods, category: selectedCategory)
    }
    
    func design() {
        setupPhoto()
        setupFoodName()
        setupCookTimeLabel()
        setupSaveButton()
        setupMenuController()
        setupCollectionView()
        setupLayout()
        setupRefreshButton()
        setupIndicator()
    }
    
    func setupCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        view.backgroundColor = .systemBackground
        collectionView.backgroundColor = .systemBackground
        
        self.collectionView.register(IngredientCell.self, forCellWithReuseIdentifier: IngredientCell.identifier)
        self.collectionView.register(RecipeShowFoodCell.self, forCellWithReuseIdentifier: RecipeShowFoodCell.identifier)
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 0
        }
        
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
    }
    
    func setupMenuController() {
        menuController.delegate = self
        
        menuController.collectionView.selectItem(at: [0,0], animated: true, scrollPosition: .centeredHorizontally)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let x = targetContentOffset.pointee.x
        let item = x / view.frame.width
        let indexPath = IndexPath(item: Int(item), section: 0)
        menuController.collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        menuController.collectionView.allowsMultipleSelection = false
    }
    
    func didTapMenuItem(indexPath: IndexPath) {
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
    
    
    @objc func saveRecipe() {
        Task{
            guard let recipe else { return }
            await viewModel.saveRecipe(recipe)
        }
    }
    
    private func backButton() {
        let home = HomeViewController()
        self.navigationController?.popToViewController(home, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let x = scrollView.contentOffset.x
        let offset = x / 2
        menuController.menuBar.transform = CGAffineTransform(translationX: offset, y: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IngredientCell.identifier, for: indexPath) as! IngredientCell
            if let recipe = recipe {
                cell.configure(recipe: recipe)
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RecipeShowFoodCell.identifier, for: indexPath) as! RecipeShowFoodCell
            if let recipe = recipe {
                cell.configure(recipe: recipe)
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: collectionView.frame.height)
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
                collectionView.reloadData()
                
            case .showError(let error):
                presentAlertOnMainThread(
                    title: LocaleKeys.Error.alert.rawValue.locale(),
                    message: error.localizedDescription,
                    buttonTitle: LocaleKeys.Error.okButton.rawValue.locale())
                
            case .saveRecipe:
                Task{
                    await self.viewModel.saveRecipe(self.recipe)
                }
                
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
                    let alert = WhichFood.showAlert(title: LocaleKeys.DetailRecipe.success.rawValue.locale(),
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
    
    func setupLayout() {
        let menuView = menuController.view!
        
        view.addSubview(menuView)
        view.addSubview(collectionView)
        
        menuView.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(40)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(menuView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(saveButton.snp.top)
        }
    }
    
    func setupRefreshButton() {
        let image = UIImage(named: "refresh")?.withRenderingMode(.alwaysTemplate).withTintColor(Colors.accent.color)
        
        refreshButton = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(refreshButtonTapped))
        navigationItem.rightBarButtonItem = refreshButton
    }
    
    func setupSaveButton() {
        view.addSubview(saveButton)
        
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            saveButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -view.bounds.height * 0.05),
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
