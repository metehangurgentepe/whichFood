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
    func delete(index: Int)
    func navigate(to navigationType: NavigationType)
}

enum NavigationType {
    case details(Int)
}

class HomeViewController: DataLoadingVC {
    private lazy var nextButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = Colors.primary.color
        button.setTitle(NSLocalizedString(LocaleKeys.Home.button.rawValue, comment:"button"), for: .normal)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        return button
    }()
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.rowHeight = 85
        table.separatorStyle = .none
        table.separatorInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        table.register(RecipeCell.self, forCellReuseIdentifier: "recipeCell")
        return table
    }()
    private let customNavigationBar: UINavigationBar = {
            let navBar = UINavigationBar()
            return navBar
    }()
    
    private lazy var categoryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 35)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(CategoryButtonCell.self, forCellWithReuseIdentifier: CategoryButtonCell.identifier)
        return collectionView
    }()
    
    var label : UILabel = {
        let label = UILabel()
        label.text = LocaleKeys.Home.noItem.rawValue.locale()
        label.textColor = .gray.withAlphaComponent(0.5)
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .headline)
        return label
    }()
    
    lazy var viewModel = HomeViewModel()
    var delegate : HomeViewModelProtocol!
    var recipes = [Recipe]()
    let categories = Categories.categoriesList
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        viewModel.delegate = self
        viewModel.getRecipes()
        label.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.getRecipes()
    }
    
    @objc func showCameraAlert() {
        let alert = showAlert(title: LocaleKeys.Home.takePhoto.rawValue.locale(),
                              message: LocaleKeys.Home.showAlert.rawValue.locale(),
                              buttonTitle: LocaleKeys.Error.backButton.rawValue.locale(),
                              secondButtonTitle: LocaleKeys.Error.okButton.rawValue.locale(),
                              completionHandler: {
//            self.dismiss(animated: true)
        }, completionSecondHandler: {
            self.goToCamera()
        }
        )
        self.present(alert, animated: true)
    }
    
    @objc func goToCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    @objc func goToPremium() {
        let vc = PremiumVC()
        self.present(vc, animated: true)
    }
    
    private func stopSkeletonAnimation() {
            tableView.stopSkeletonAnimation()
            tableView.hideSkeleton(reloadDataAfter: false, transition: .crossDissolve(0.2))
    }
    
    private func configure() {
        navigationItem.largeTitleDisplayMode = .always
        self.view.backgroundColor = .systemBackground
        title = LocaleKeys.Home.recipe.rawValue
        
        tableView.delegate = self
        tableView.dataSource = self
        categoryCollectionView.delegate = self
        categoryCollectionView.dataSource = self
        
        navigationItem.hidesBackButton = true
        
        settingsButton()
        setupLabels()
        setupCategoryButtons()
        setUpButton()
        setupRecipeTable()
        
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
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension HomeViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                let vc = ImageToTextVC()
                self.navigationController?.pushViewController(vc, animated: true)
                picker.dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: Design Extension
extension HomeViewController {
    
    private func setupLabels() {
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            label.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            
            label.heightAnchor.constraint(equalToConstant: 40),
            label.widthAnchor.constraint(equalToConstant: view.bounds.width),
        ])
    }
    
    private func setUpButton() {
        self.view.addSubview(nextButton)
        
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nextButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            nextButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -15),
            nextButton.heightAnchor.constraint(equalToConstant: view.bounds.height * 0.07),
            nextButton.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.85)
        ])
    }

    private func setupRecipeTable() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: categoryCollectionView.bottomAnchor),
            tableView.bottomAnchor.constraint(equalTo: nextButton.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
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

// MARK: Table view extension
extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recipes.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.selectRecipe(at: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recipeCell", for: indexPath) as! RecipeCell
        let recipe = recipes[indexPath.row]
        cell.foodName.text = recipe.name
        cell.ingredientLabel.text = recipe.ingredients.joined(separator: ", ")
        cell.createdTime.text = formatDate(recipe.createdAt)
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            let id = recipes[indexPath.row].id
            viewModel.delete(id: id,index: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.reloadData()
            tableView.endUpdates()
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .delete
    }
}

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        categories.count
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
    
}

// MARK: DELEGATE EXTENSION
extension HomeViewController: HomeViewModelDelegate {
    func navigate(to navigationType: NavigationType) {
        switch navigationType {
        case .details(let index):
            let recipe = recipes[index]
            let viewModel = DetailRecipeViewModel(recipe: recipe)
            let viewController = DetailRecipeBuilder.make(with: viewModel)
            show(viewController, sender: nil)
        }
    }
    
    func delete(index: Int) {
        recipes.remove(at: index)
        tableView.reloadData()
    }
    
    func handleViewModelOutput(_ output: RecipeListViewModelOutput) {
        DispatchQueue.main.async {[weak self] in
            guard let self = self else { return }
            switch output {
            case .setLoading(let isLoading):
                if isLoading {
                    self.showLoadingView()
                } else {
                    self.dismissLoadingView()
                }
                
            case .showRecipeList(let recipes):
                    self.recipes = recipes
                    self.tableView.reloadData()
                    if recipes.count != 0 {
                        self.label.isHidden = true
                    }
                
            case.emptyList:
                    self.label.isHidden = false
                
            case .showError(let error):
                let alert = showAlert(title: LocaleKeys.Error.alert.rawValue.locale(),
                                      message: error.localizedDescription,
                                      buttonTitle: LocaleKeys.Error.okButton.rawValue.locale(), secondButtonTitle: nil)
                self.present(alert, animated: true)
            }
        }
    }
}





