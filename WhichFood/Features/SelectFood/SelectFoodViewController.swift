//
//  SelectFoodViewController.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 12.09.2023.
//

import UIKit


class SelectFoodViewController: UIViewController {
    private lazy var tableView = UITableView()
    private lazy var button : UIButton = {
        let button = UIButton()
        button.setTitle(LocaleKeys.SelectFood.applyButton.rawValue.locale(), for: .normal)
        button.backgroundColor = Colors.primary.color
        button.layer.cornerRadius = 12
        return button
    }()
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        var indicator = UIActivityIndicatorView()
        indicator = UIActivityIndicatorView(style: .large)
        indicator.isHidden = true
        indicator.color = .black
        return indicator
    }()
    
    private var searchField = UISearchController(searchResultsController: nil)
    var categories : [String] = []
    lazy var viewModel = SelectFoodViewModel()
    
    private lazy var categoryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 10
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(CategoryCell.self, forCellWithReuseIdentifier: CategoryCell.identifier)
        collectionView.contentInset = .init(top: 0, left: 10, bottom: 0, right: 0)
        return collectionView
    }()
    
    private lazy var blurEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        return blurEffectView
    }()
    
    private var categoryCollectionViewHeightConstraint: NSLayoutConstraint?
    private let categoryCollectionViewHeight: CGFloat = 50
    private var prevScrollDirection: CGFloat = 0
    private var selectedCategoryIndexPath: IndexPath?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        viewModel.delegate = self
        configure()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupNavBar()
    }
    
    
    private func configure() {
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never
        
        view.addSubview(blurEffectView)
        view.addSubview(tableView)
        view.addSubview(button)
        view.addSubview(categoryCollectionView)
    
        setupCategoryCollectionView()
        setupTableView()
        setupButton()
        setupSearchField()
    }
    
    private func setupNavBar() {
        navigationController?.navigationBar.tintColor = .label

        // Add right navigation button for selected items
        let selectedItemsButton = UIBarButtonItem(
            image: UIImage(systemName: "list.clipboard"),
            style: .plain,
            target: self,
            action: #selector(showSelectedItems)
        )
        navigationItem.rightBarButtonItem = selectedItemsButton
    }
    
    private func setupCategoryCollectionView() {
        categoryCollectionViewHeightConstraint = categoryCollectionView.heightAnchor.constraint(equalToConstant: categoryCollectionViewHeight)
        
        categoryCollectionView.dataSource = self
        categoryCollectionView.delegate = self
        
        categoryCollectionView.translatesAutoresizingMaskIntoConstraints = false
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            blurEffectView.topAnchor.constraint(equalTo: view.topAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: categoryCollectionView.bottomAnchor),
            
            categoryCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            categoryCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoryCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            categoryCollectionViewHeightConstraint!,
        ])
    }
    
    @objc func didTapButton(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1, animations: {
            self.button.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            self.button.alpha = 0.5
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.button.transform = CGAffineTransform.identity
                self.button.alpha = 1
            }
        }
        Task{
            try await viewModel.increaseApiUsage()
        }
    }

    @objc private func showSelectedItems() {
        presentSelectedItemsBottomSheet()
    }

    private func presentSelectedItemsBottomSheet() {
        let alertController = UIAlertController(title: LocaleKeys.SelectFood.selectedIngredients.rawValue.locale(), message: nil, preferredStyle: .actionSheet)

        if viewModel.selectedFoods.isEmpty {
            alertController.message = LocaleKeys.SelectFood.noIngredientsSelected.rawValue.locale()
        } else {
            alertController.message = String(format: LocaleKeys.SelectFood.ingredientsSelectedCount.rawValue.locale(), viewModel.selectedFoods.count)

            for (index, ingredient) in viewModel.selectedFoods.enumerated() {
                let action = UIAlertAction(title: "❌ \(ingredient.name)", style: .destructive) { [weak self] _ in
                    self?.viewModel.toggleIngredientSelection(ingredient)
                    self?.updateVisibleCells()
                }
                alertController.addAction(action)
            }
        }

        let cancelAction = UIAlertAction(title: LocaleKeys.SelectFood.closeButton.rawValue.locale(), style: .cancel)
        alertController.addAction(cancelAction)

        if let popover = alertController.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }

        present(alertController, animated: true)
    }

    private func updateVisibleCells() {
        DispatchQueue.main.async {
            for indexPath in self.tableView.indexPathsForVisibleRows ?? [] {
                if let cell = self.tableView.cellForRow(at: indexPath) as? SelectFoodCell {
                    let ingredient: Ingredient
                    if self.viewModel.inSearchMode(self.searchField) {
                        ingredient = self.viewModel.filteredFoods[indexPath.row]
                    } else {
                        let categories = Array(self.viewModel.categorizedIngredients.keys)
                        let category = categories[indexPath.section]
                        ingredient = self.viewModel.categorizedIngredients[category]![indexPath.row]
                    }
                    cell.updateCheckbox(isSelected: self.viewModel.isIngredientSelected(ingredient), animated: true)
                }
            }
        }
    }
    
    func header(title: String) -> UIView {
        let header = UIView()
        header.backgroundColor = .clear
        
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
        let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
        vibrancyView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = title
        label.font = .preferredFont(forTextStyle: .headline).withSize(20)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        
        header.addSubview(blurView)
        blurView.contentView.addSubview(vibrancyView)
        vibrancyView.contentView.addSubview(label)
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: header.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: header.bottomAnchor),
            
            vibrancyView.topAnchor.constraint(equalTo: blurView.topAnchor),
            vibrancyView.leadingAnchor.constraint(equalTo: blurView.leadingAnchor),
            vibrancyView.trailingAnchor.constraint(equalTo: blurView.trailingAnchor),
            vibrancyView.bottomAnchor.constraint(equalTo: blurView.bottomAnchor),
            
            label.leadingAnchor.constraint(equalTo: vibrancyView.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: vibrancyView.centerYAnchor)
        ])
        
        return header
    }
}


// MARK: Self Design Functions
extension SelectFoodViewController {
    func updateCheckbox(_ isSelected: Bool) -> UIImage{
        if isSelected {
            return Images.selectedCheck ?? UIImage()
        } else {
            return Images.unselectedCheck ?? UIImage()
        }
    }
    
    func setupSearchField() {
        searchField.searchResultsUpdater = self
        searchField.obscuresBackgroundDuringPresentation = false
        searchField.hidesNavigationBarDuringPresentation = false
        searchField.searchBar.placeholder = LocaleKeys.SelectFood.searchFood.rawValue.locale()
        searchField.searchBar.searchTextField.leftView?.tintColor = Colors.accent.color
        searchField.searchBar.tintColor = Colors.accent.color
        
        self.navigationItem.searchController = searchField
        self.definesPresentationContext = false
        self.navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    func setupTableView() {
        tableView.rowHeight = 60
        tableView.register(SelectFoodCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.tableHeaderView = nil
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: self.categoryCollectionView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            
            tableView.heightAnchor.constraint(equalToConstant: view.bounds.height * 0.72),
            tableView.widthAnchor.constraint(equalToConstant: view.bounds.width)
        ])
    }
    
    func setupButton() {
        view.addSubview(button)
        button.addSubview(loadingIndicator)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.bottomAnchor.constraint(equalTo: self.view.bottomAnchor,constant: -view.bounds.height * 0.05),
            button.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            
            button.heightAnchor.constraint(equalToConstant: 50),
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor,constant: 20),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: button.centerYAnchor),
        ])
        
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
    }
}

extension SelectFoodViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollViewY = scrollView.contentOffset.y
        let scrollSizeHeight = scrollView.contentSize.height
        let scrollFrameHeight = scrollView.frame.height
        let scrollHeight = scrollSizeHeight - scrollFrameHeight
        
        if prevScrollDirection > scrollViewY && prevScrollDirection < scrollHeight {
            UIView.animate(withDuration: 0.3) {
                self.button.alpha = 1
            }
        } else if prevScrollDirection < scrollViewY && scrollViewY > 0 {
            UIView.animate(withDuration: 0.3) {
                self.button.alpha = 0.3
            }
        }
        
        prevScrollDirection = scrollView.contentOffset.y
    }
}

// MARK: Tableview extension
extension SelectFoodViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if viewModel.inSearchMode(searchField) {
            return 1
        } else {
            return viewModel.categorizedIngredients.keys.count
        }
    }
    
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if viewModel.inSearchMode(searchField) {
            return LocaleKeys.SelectFood.filter.rawValue.locale()
        } else {
            let categories = Array(viewModel.categorizedIngredients.keys)
            return categories[section].locale()
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewModel.inSearchMode(searchField) {
            return viewModel.filteredFoods.count
        } else {
            let categories = Array(viewModel.categorizedIngredients.keys)
            let category = categories[section]
            return viewModel.categorizedIngredients[category]?.count ?? 0
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SelectFoodCell
        
        let ingredient: Ingredient
        if viewModel.inSearchMode(searchField) {
            ingredient = viewModel.filteredFoods[indexPath.row]
        } else {
            let categories = Array(viewModel.categorizedIngredients.keys)
            let category = categories[indexPath.section]
            ingredient = viewModel.categorizedIngredients[category]![indexPath.row]
        }
        
        cell.configure(with: ingredient)
        cell.updateCheckbox(isSelected: viewModel.isIngredientSelected(ingredient), animated: false)
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedIngredient: Ingredient

        if viewModel.inSearchMode(searchField) {
            selectedIngredient = viewModel.filteredFoods[indexPath.row]
        } else {
            let categories = Array(viewModel.categorizedIngredients.keys)
            let category = categories[indexPath.section]
            guard let foods = viewModel.categorizedIngredients[category] else { return }
            selectedIngredient = foods[indexPath.row]
        }

        viewModel.toggleIngredientSelection(selectedIngredient)

        // Only reload the specific cell instead of entire table
        if let cell = tableView.cellForRow(at: indexPath) as? SelectFoodCell {
            cell.updateCheckbox(isSelected: viewModel.isIngredientSelected(selectedIngredient), animated: true)
        }

        // Still call delegate for other potential updates
        viewModel.delegate?.onIngredientsUpdated()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if viewModel.inSearchMode(searchField) {
            let title = LocaleKeys.SelectFood.filter.rawValue.locale()
            return header(title: title)
        } else {
            let categories = Array(viewModel.categorizedIngredients.keys)
            let category = categories[section].locale()
            return header(title: category)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension SelectFoodViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.categorizedIngredients.keys.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCell.identifier, for: indexPath) as! CategoryCell
        let categories = Array(viewModel.categorizedIngredients.keys)
        cell.configure(title: categories[indexPath.item])
        
        if indexPath == selectedCategoryIndexPath {
            cell.label.layer.borderWidth = 0
            cell.label.backgroundColor = Colors.accent.color
            cell.label.textColor = .white
        } else {
            cell.label.layer.borderWidth = 0
            cell.label.layer.borderColor = Colors.accent.color.cgColor
            cell.label.backgroundColor = .clear
            cell.label.textColor = Colors.accent.color
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let previousSelectedIndexPath = selectedCategoryIndexPath,
           let previousCell = collectionView.cellForItem(at: previousSelectedIndexPath) as? CategoryCell {
            previousCell.label.layer.borderWidth = 1
            previousCell.label.layer.borderColor = Colors.accent.color.cgColor
            previousCell.label.backgroundColor = .clear
            previousCell.label.textColor = Colors.accent.color
        }
        
        selectedCategoryIndexPath = indexPath
        if let cell = collectionView.cellForItem(at: indexPath) as? CategoryCell {
            cell.label.layer.borderWidth = 0
            cell.label.backgroundColor = Colors.accent.color
            cell.label.textColor = .white
        }
        
        let categories = Array(viewModel.categorizedIngredients.keys).sorted()
        let selectedCategory = categories[indexPath.item]
        
        if let sectionIndex = viewModel.categorizedIngredients.keys.sorted().firstIndex(of: selectedCategory) {
            let tableViewIndexPath = IndexPath(row: 0, section: sectionIndex)
            tableView.scrollToRow(at: tableViewIndexPath, at: .top, animated: true)
        }
        
        collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let categories = Array(viewModel.categorizedIngredients.keys)
        let text = categories[indexPath.item]
        let cellWidth = text.size(withAttributes:[.font: UIFont.systemFont(ofSize:12)]).width + 50
        return CGSize(width: cellWidth, height: 30.0)
    }
    
    private func toggleCategoryCollectionView(show: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.categoryCollectionViewHeightConstraint?.constant = show ? self.categoryCollectionViewHeight : 0
            self.view.layoutIfNeeded()
        }
    }
}


extension SelectFoodViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""
        
        self.viewModel.updateSearchController(searchBarText: searchText)
        
        toggleCategoryCollectionView(show: searchText.isEmpty)
    }
}


//MARK: Delegate extension
extension SelectFoodViewController: SelectFoodViewDelegate {
    func navigate() {
        DispatchQueue.main.async{
            let vc = ShowFoodVC()
            let vm = ShowFoodViewModel()
            vc.selectedFoods = self.viewModel.selectedFoods
            vc.selectedCategory = self.categories
            vm.selectedFoods = self.viewModel.selectedFoods
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func buttonLoading(isLoading: Bool) {
        if isLoading {
            DispatchQueue.main.async{
                self.loadingIndicator.isHidden = false
                self.loadingIndicator.startAnimating()
                self.button.setTitle("", for: .normal)
                self.button.setTitle("", for: .highlighted)
                self.button.isEnabled = false
                self.button.backgroundColor = .systemGray
            }
        } else {
            DispatchQueue.main.async{
                self.loadingIndicator.stopAnimating()
                self.loadingIndicator.isHidden = true
                self.button.setTitle(LocaleKeys.SelectFood.applyButton.rawValue.locale(), for: .normal)
                self.button.isEnabled = true
                self.button.backgroundColor = Colors.primary.color
            }
        }
    }
    
    func onError(_ error: WFError) {
        DispatchQueue.main.async{
            var alert = UIAlertController()
            switch error {
            case WFError.apiUsageError:
                alert = showAlert(
                    title: LocaleKeys.Error.alert.rawValue.locale(),
                    message:LocaleKeys.Error.apiUsageError.rawValue.locale() ,
                    buttonTitle: LocaleKeys.Error.okButton.rawValue.locale(),
                    secondButtonTitle: LocaleKeys.Error.backButton.rawValue.locale(),
                    completionHandler: {
                        let vc = PremiumVC()
                        self.present(vc, animated: true )
                    },completionSecondHandler: {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                )
            default:
                alert = showAlert(
                    title: LocaleKeys.Error.alert.rawValue.locale(),
                    message:LocaleKeys.Error.oocured.rawValue.locale() ,
                    buttonTitle: LocaleKeys.Error.okButton.rawValue.locale(),
                    secondButtonTitle: LocaleKeys.Error.backButton.rawValue.locale()
                )
            }
            self.present(alert, animated: true)
        }
    }
    
    func onIngredientsUpdated() {
        DispatchQueue.main.async {
            // Only reload data when in search mode, otherwise use updateVisibleCells
            if self.viewModel.inSearchMode(self.searchField) {
                self.tableView.reloadData()
            } else {
                self.updateVisibleCells()
            }

            if let searchText = self.searchField.searchBar.text, searchText.isEmpty {
                self.toggleCategoryCollectionView(show: true)
            }
        }
    }
}


