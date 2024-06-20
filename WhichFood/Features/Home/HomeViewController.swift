//
//  HomeViewController.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 11.09.2023.
//

import UIKit
import SkeletonView

protocol HomeViewModelDelegate: AnyObject{
    func handleViewModelOutput(_ output: RecipeListViewModelOutput)
    func navigate(to navigationType: NavigationType)
}

enum NavigationType {
    case details(Int)
    case goToVC(UIViewController)
    case present(UIViewController)
}

class HomeViewController: DataLoadingVC, HomeRecipeCellDelegate {
    
    enum Section {
        case main
    }
    
    private lazy var nextButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = Colors.primary.color
        button.setTitle(NSLocalizedString(LocaleKeys.Home.button.rawValue, comment:"button"), for: .normal)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        return button
    }()
    
    private lazy var categoryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 70, height: 35)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(CategoryButtonCell.self, forCellWithReuseIdentifier: CategoryButtonCell.identifier)
        return collectionView
    }()
    
    var recipeCollectionView: UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<Section, Recipe>!
    
    
    lazy var viewModel = HomeViewModel()
    var delegate : HomeViewModelProtocol!
    var recipes = [Recipe]()
    let categories = Categories.homeCategoryList
    var counter = 0
    var categoryIndexPath: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        viewModel.delegate = self
        
        recipeCollectionView.delegate = self
        configureDataSource()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.getRecipes()
        if categoryIndexPath != nil {
            categoryCollectionView.deselectItem(at: categoryIndexPath!, animated: true)
        }
    }
    
    
    @objc func showCameraAlert() {
        let alert = showAlert(title: LocaleKeys.Home.takePhoto.rawValue.locale(),
                              message: LocaleKeys.Home.showAlert.rawValue.locale(),
                              buttonTitle: LocaleKeys.Error.backButton.rawValue.locale(),
                              secondButtonTitle: LocaleKeys.Error.okButton.rawValue.locale(),
                              completionHandler: {
        }, completionSecondHandler: {
            self.goToCamera()
        }
        )
        self.present(alert, animated: true)
    }
    
    
    func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource(collectionView: recipeCollectionView, cellProvider: { collectionView, indexPath, follower in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeRecipeCell.identifier, for: indexPath) as! HomeRecipeCell
            let recipe = self.recipes[indexPath.row]
            cell.configure(recipe: recipe)
            cell.delegate = self
            return cell
        })
    }
    
    
    func deleteRecipe(recipe: Recipe) {
        viewModel.deleteRecipe(recipe: recipe)
    }
    
    
    func showError(error: Error) {
        self.delegate.delegate?.handleViewModelOutput(.showError(error as! WFError))
    }
    
    
    func updatedData(on recipes: [Recipe]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Recipe>()
        snapshot.appendSections([.main])
        snapshot.appendItems(recipes)
        DispatchQueue.main.async{
            self.dataSource.apply(snapshot,animatingDifferences: true)
        }
    }
    
    
    @objc func goToCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        viewModel.delegate?.navigate(to: .present(imagePicker))
    }
    
    
    @objc func goToPremium() {
        let vc = PremiumVC()
        viewModel.delegate?.navigate(to: .present(vc))
    }
    
    
    private func configure() {
        navigationItem.largeTitleDisplayMode = .always
        self.view.backgroundColor = .systemBackground
        title = LocaleKeys.Home.recipe.rawValue.locale()
        
        categoryCollectionView.delegate = self
        categoryCollectionView.dataSource = self
        
        navigationItem.hidesBackButton = true
        
        connfigureDiscoverRecipeBarButton()
        settingsButton()
        setupCategoryButtons()
        setUpButton()
        configureCollectionView()
    }
    
    
    @objc func didTapButton() {
        UIView.animate(withDuration: 0.1, animations: {
            self.nextButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            self.nextButton.alpha = 0.5
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.nextButton.transform = CGAffineTransform.identity
                self.nextButton.alpha = 1
            }
        }
        let vc = SelectCategoryVC()
        vc.hidesBottomBarWhenPushed = true
        viewModel.delegate?.navigate(to: .goToVC(vc))
    }
}

extension HomeViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if info[UIImagePickerController.InfoKey.originalImage] is UIImage {
            let vc = ImageToTextVC()
            self.navigationController?.pushViewController(vc, animated: true)
            picker.dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: Design Extension
extension HomeViewController {
    func configureCollectionView() {
        recipeCollectionView = UICollectionView(frame: .zero, collectionViewLayout: UIHelper.createTwoColumntFlowLayout(in: view))
        view.addSubview(recipeCollectionView)
        recipeCollectionView.backgroundColor = .systemBackground
        recipeCollectionView.register(HomeRecipeCell.self, forCellWithReuseIdentifier: HomeRecipeCell.identifier)
        
        recipeCollectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            recipeCollectionView.topAnchor.constraint(equalTo: categoryCollectionView.bottomAnchor, constant: -2),
            recipeCollectionView.bottomAnchor.constraint(equalTo: nextButton.topAnchor),
            recipeCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            recipeCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
    
    private func setUpButton() {
        self.view.addSubview(nextButton)
        
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nextButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            nextButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -15),
            nextButton.heightAnchor.constraint(equalToConstant: view.bounds.height * 0.05),
            nextButton.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.85)
        ])
    }
    
    private func setupCategoryButtons() {
        view.addSubview(categoryCollectionView)
        
        categoryCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            categoryCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            categoryCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor,constant: 20),
            categoryCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor,constant: 0),
            categoryCollectionView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    
    private func connfigureDiscoverRecipeBarButton() {
        let image = SFSymbols.wandAndStars!.withRenderingMode(.alwaysOriginal).withTintColor(.gray)
        let discoverButton = UIBarButtonItem(image: image, style: .done, target: self, action: #selector(navigateToDiscoverScreen))
        navigationItem.leftBarButtonItem = discoverButton
    }
    
    
    @objc func navigateToDiscoverScreen() {
        Task{
            try await viewModel.increaseApiUsage()
        }
    }
    
    
    private func settingsButton() {
        let circularView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        circularView.layer.cornerRadius = 15
        circularView.backgroundColor = UIColor.orange
        
        let cameraImageView = UIImageView(image: Images.camera)
        cameraImageView.contentMode = .scaleAspectFit
        cameraImageView.tintColor = UIColor.white
        
        let centeredFrame = CGRect(
            x: (circularView.bounds.width - circularView.bounds.width * 0.65) / 2,
            y: (circularView.bounds.height - circularView.bounds.height * 0.65) / 2,
            width: circularView.bounds.width * 0.65,
            height: circularView.bounds.height * 0.65
        )
        cameraImageView.frame = centeredFrame
        
        circularView.addSubview(cameraImageView)
        
        let cameraButton = UIBarButtonItem(customView: circularView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showCameraAlert))
        circularView.addGestureRecognizer(tapGesture)
        
        let premiumButton = UIBarButtonItem(image: Images.premium?.withTintColor(Colors.crownColor.color, renderingMode: .alwaysOriginal), style: .done, target: self, action: #selector(goToPremium))
        
        navigationItem.rightBarButtonItems = [
            cameraButton,
            premiumButton
        ]
    }
}

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryButtonCell.identifier, for: indexPath) as! CategoryButtonCell
        let category = categories[indexPath.item]
        cell.configure(title: category)
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 200, height: 40)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch collectionView {
        case recipeCollectionView:
            viewModel.delegate?.navigate(to: .details(indexPath.row))
            
        case categoryCollectionView:
            categoryIndexPath = indexPath
            let category = categories[indexPath.item]
            viewModel.filter(word: category)
        default:
            break
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            return self.makeContextMenu(for: indexPaths.first!)
        }
    }
    
    
    func makeContextMenu(for indexPath: IndexPath) -> UIMenu {
        let deleteAction = UIAction(title: "Delete", image: SFSymbols.deleteIcon) { _ in
            self.viewModel.deleteRecipe(recipe: self.recipes[indexPath.row])
            self.updatedData(on: self.recipes)
        }
        
        let contextMenu = UIMenu(title: "", children: [deleteAction])
        return contextMenu
    }
}

// MARK: DELEGATE EXTENSION
extension HomeViewController: HomeViewModelDelegate {
    func navigate(to navigationType: NavigationType) {
        DispatchQueue.main.async{ [weak self] in
            guard let self = self else { return }
            switch navigationType {
            case .details(let index):
                let recipe = recipes[index]
                let viewModel = DetailRecipeViewModel(recipe: recipe)
                let viewController = DetailRecipeBuilder.make(with: viewModel)
                show(viewController, sender: nil)
                
            case .goToVC(let vc):
                self.navigationController?.pushViewController(vc, animated: true)
                
            case .present(let vc):
                self.present(vc,animated:true)
            }
        }
    }
    
    
    func handleViewModelOutput(_ output: RecipeListViewModelOutput) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch output {
            case .setLoading(let isLoading):
                if isLoading {
                    self.customLoadingView()
                } else {
                    self.dismissLoadingView()
                }
                
            case .showRecipeList(let recipes):
                self.recipes = recipes
                updatedData(on: self.recipes)
                hideEmptyStateView(in: recipeCollectionView)
                
            case.emptyList:
                showEmptyStateView(with: LocaleKeys.Home.noItem.rawValue.locale(), in: recipeCollectionView)
                
            case .showError(let error):
                presentAlertOnMainThread(
                    title: LocaleKeys.Error.alert.rawValue.locale(),
                    message: error.localizedDescription,
                    buttonTitle: LocaleKeys.Error.okButton.rawValue.locale()
                )
            }
        }
    }
}





