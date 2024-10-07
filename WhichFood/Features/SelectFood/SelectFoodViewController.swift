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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        viewModel.delegate = self
        configure()
    }
    
    
    private func configure() {
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never
        
        view.addSubview(tableView)
        view.addSubview(button)
        
        setupTableView()
        setupButton()
        setupSearchField()
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
            tableView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
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
            button.widthAnchor.constraint(equalToConstant: self.view.bounds.width * 0.8)
        ])
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: button.centerYAnchor),
        ])
        
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
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
        
        if viewModel.inSearchMode(searchField) {
            let food = viewModel.filteredFoods[indexPath.row]
            cell.configure(with: food)
        } else {
            let categories = Array(viewModel.categorizedIngredients.keys)
            
            let category = categories[indexPath.section]
            
            if let foods = viewModel.categorizedIngredients[category] {
                let food = foods[indexPath.row]
                cell.configure(with: food)
            }
        }
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if viewModel.inSearchMode(searchField) {
            let food = viewModel.filteredFoods[indexPath.row]
            viewModel.filteredFoods[indexPath.row].isSelected.toggle()
            
            if var array = viewModel.categorizedIngredients[food.category.rawValue] {
                if let index = array.firstIndex(where: { $0.name == food.name }) {
                    array[index].isSelected.toggle()
                }
                viewModel.categorizedIngredients.updateValue(array, forKey: food.category.rawValue)
            }
            
            viewModel.chooseIngredient(ingredient: food)
            
            viewModel.delegate?.onIngredientsUpdated()
        } else {
            let categories = Array(viewModel.categorizedIngredients.keys)
            let category = categories[indexPath.section]
            
            guard var foods = viewModel.categorizedIngredients[category] else {
                return
            }
            
            foods[indexPath.row].isSelected.toggle()
            viewModel.chooseIngredient(ingredient: foods[indexPath.row])
            viewModel.categorizedIngredients[category] = foods
            
            viewModel.delegate?.onIngredientsUpdated()
        }
    }
}

extension SelectFoodViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        self.viewModel.updateSearchController(searchBarText: searchController.searchBar.text)
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
            self.tableView.reloadData()
        }
    }
}

