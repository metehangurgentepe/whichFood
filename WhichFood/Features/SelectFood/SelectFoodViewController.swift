//
//  SelectFoodViewController.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 12.09.2023.
//

import UIKit


protocol SelectFoodViewDelegate: AnyObject {
    func onIngredientsUpdated()
    func onError(_ error: Error)
    func buttonLoading(isLoading: Bool)
    func navigate()
}

class SelectFoodViewController: UIViewController {
//    private lazy var viewModel = SelectFoodViewModel()
    private lazy var tableView = UITableView()
    private lazy var button : UIButton = {
        let button = UIButton()
        button.setTitle(NSLocalizedString(LocaleKeys.SelectFood.applyButton.rawValue, comment:"Apply Button"), for: .normal)
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
    
    /// design functions
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
            return UIImage(named: "checkmark.square.fill") ?? UIImage()
        } else {
            return UIImage(named: "rectangle") ?? UIImage()
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
        tableView.register(CustomCell.self, forCellReuseIdentifier: "cell")
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let inSearchMode = self.viewModel.inSearchMode(searchField)
        return inSearchMode ? self.viewModel.filteredFoods.count : self.viewModel.foods.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomCell
        let inSearchMode = self.viewModel.inSearchMode(searchField)
        let ingredient = viewModel.inSearchMode(searchField) ? viewModel.filteredFoods[indexPath.row] : viewModel.foods[indexPath.row]
        cell.configure(with: ingredient)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        viewModel.chooseIngredient(index:indexPath.row, searchController: searchField)
        print(viewModel.foods.filter{$0.isSelected == true})
        print(viewModel.selectedFoods.count)
    }
}

extension SelectFoodViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        self.viewModel.updateSearchController(searchBarText: searchController.searchBar.text)
        print(viewModel.filteredFoods)
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
                self.button.setTitle("", for: .highlighted)
            }
        } else {
            DispatchQueue.main.async{
                self.loadingIndicator.stopAnimating()
                self.loadingIndicator.isHidden = true
                self.button.setTitle(LocaleKeys.SelectFood.applyButton.rawValue.locale(), for: .normal)
            }
        }
    }
    
    func onError(_ error: Error) {
        DispatchQueue.main.async{
            var alert = UIAlertController()
            switch error {
            case ApiUsageError.exceededApiLimit:
                alert = showAlert(
                    title: LocaleKeys.Error.alert.rawValue.locale(),
                    message:LocaleKeys.Error.apiUsageError.rawValue.locale() ,
                    buttonTitle: LocaleKeys.Error.okButton.rawValue.locale(),
                    secondButtonTitle: LocaleKeys.Error.backButton.rawValue.locale(),
                    completionHandler: {
                        let vc = PremiumVC()
                        self.present(vc, animated: true )
                    },completionSecondHandler: {
                        self.dismiss(animated: true)
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

