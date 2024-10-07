//
//  DetailRecipeVC.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 16.09.2023.
//

import UIKit
import Kingfisher
import SDWebImage


class DetailRecipeVC: UICollectionViewController, UICollectionViewDelegateFlowLayout, MenuDetailControllerDelegate {
    lazy var imageView = UIImageView()
    private lazy var cookTimeLabel = UILabel()
    private lazy var foodNameLabel = UILabel()
    private lazy var errorAlert = UIAlertAction()
    private lazy var favButton = UIBarButtonItem(image: SFSymbols.favorites, style: .plain, target: self, action: #selector(addFav))
    
    var viewModel : DetailRecipeViewModelProtocol?
    var recipe: Recipe?
    let menuController = MenuDetailController(collectionViewLayout: UICollectionViewFlowLayout())

    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel?.delegate = self
        viewModel?.load()
        design()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let backButton = navigationController?.navigationBar.backItem?.backBarButtonItem {
            backButton.tintColor = Colors.accent.color
        }
        
        navigationController?.navigationBar.tintColor = Colors.accent.color
    }
    
    func design() {
        configureNavigationBar()
        configureFavButton()
        configureViewController()
        setupPhoto()
        setupFoodName()
        setupCookTimeLabel()
        setupMenuController()
        setupCollectionView()
        updateColorsWhenTraitColor()
        setupLayout()
    }
    
    func setupMenuController() {
        menuController.delegate = self
        
        menuController.collectionView.selectItem(at: [0,0], animated: true, scrollPosition: .centeredHorizontally)
    }
    
    private func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
            
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    func setupCollectionView() {
        
        collectionView.register(IngredientDetailCell.self, forCellWithReuseIdentifier: IngredientDetailCell.identifier)
        collectionView.register(RecipeDetailCell.self, forCellWithReuseIdentifier: RecipeDetailCell.identifier)
        
        if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 0
        }
        
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    func didTapMenuItem(indexPath: IndexPath) {
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let x = scrollView.contentOffset.x
        let offset = x / 2
        menuController.menuBar.transform = CGAffineTransform(translationX: offset, y: 0)
    }
    
    override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let x = targetContentOffset.pointee.x
        let item = x / view.frame.width
        let indexPath = IndexPath(item: Int(item), section: 0)
        menuController.collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        menuController.collectionView.allowsMultipleSelection = false
    }
    
    func configureFavButton() {
        PersistenceManager.isSaved(favorite: self.recipe!) { result in
            DispatchQueue.main.async{
                switch result {
                case .success(let success):
                    if success {
                        self.favButton.image = SFSymbols.selectedFavorites?.withRenderingMode(.alwaysTemplate).withTintColor(Colors.accent.color)
                        self.favButton.action = #selector(self.removeFav)
                        self.favButton.tintColor = Colors.accent.color
                    } else {
                        self.favButton.image = SFSymbols.favorites?.withRenderingMode(.alwaysTemplate).withTintColor(Colors.accent.color)
                        self.favButton.action = #selector(self.addFav)
                        self.favButton.tintColor = Colors.accent.color
                    }
                case .failure(_):
                    break
                }
            }
        }
    }
    
    @objc func addFav() {
        PersistenceManager.updateWith(favorite: self.recipe!, actionType: .add) { error in
        }
        configureFavButton()
    }
    
    @objc func removeFav() {
        PersistenceManager.updateWith(favorite: self.recipe!, actionType: .remove) { error in
        }
        configureFavButton()
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
        
        navigationItem.rightBarButtonItem = favButton
    }
    
    
    private func updateColorsWhenTraitColor() {
        if traitCollection.userInterfaceStyle == .dark {
            
        } else {
            
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IngredientDetailCell.identifier, for: indexPath) as! IngredientDetailCell
            cell.configure(recipe: recipe!)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RecipeDetailCell.identifier, for: indexPath) as! RecipeDetailCell
            cell.configure(recipe: recipe!)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: collectionView.frame.height)
    }
}


extension DetailRecipeVC: DetailRecipeVCDelegate {
    func showDetail(_ recipe: Recipe) {
        self.recipe = recipe
        DispatchQueue.main.async {
            self.cookTimeLabel.text = recipe.cookTime
            self.foodNameLabel.text = recipe.name
            self.title = recipe.name
            
            let placeholderImage = UIImage(named: "placeholder")
            
            if let imageURL = recipe.imageUrl, let url = URL(string: imageURL) {
                
                let processor = ResizingImageProcessor(referenceSize: CGSize(width: self.imageView.bounds.width, height: self.imageView.bounds.height), mode: .aspectFill)
                
                self.imageView.kf.setImage(with: url, placeholder: placeholderImage, options: [
                    .transition(.fade(0.2)),
                    .processor(processor),
                    .progressiveJPEG(.init(isBlur: true, isFastestScan: false, scanInterval: 0.1))
                ])
            } else {
                self.imageView.image = placeholderImage
            }
        }
    }
}

extension DetailRecipeVC {
    func updateLabelsVisibility() {
        
    }
    
    func setupLayout() {
        let menuView = menuController.view!
        
        view.addSubview(menuView)
        view.addSubview(collectionView)
        
        menuView.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom)
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.height.equalTo(40)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(menuView.snp.bottom).offset(1)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
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
    
    func setupPhoto() {
        view.addSubview(imageView)
        
//        imageView.image = image
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
    
