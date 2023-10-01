//
//  SelectFoodViewController.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 12.09.2023.
//

import UIKit

class SelectFoodViewController: UIViewController {
    private let tableView = UITableView()
    private let searchTextField = UISearchController(searchResultsController: nil)
    private let button : UIButton = {
        let button = UIButton()
        button.setTitle("Apply", for: .normal)
        button.backgroundColor = Colors.primary.color
        button.layer.cornerRadius = 12
        return button
    }()
    
    var categories : [String] = []
    
    private let viewModel : SelectFoodViewModel
    
    init(_ viewModel: SelectFoodViewModel = SelectFoodViewModel()){
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        configure()
        setupTableView()
        setupSearchTextField()
        setupButton()
        
        self.viewModel.onFoodsUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
        
        tableView.dataSource = self
        tableView.delegate = self
    }
   
    
    private func configure() {
        view.addSubview(tableView)
        view.addSubview(button)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Toggle the isSelected property
        viewModel.chooseFood(index:indexPath.row)
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
        let vc = ShowFoodVC()
        let vm = ShowFoodViewModel()
        vc.selectedFoods = viewModel.selectedFoods
        vc.selectedCategory = categories
        vm.selectedFoods = viewModel.selectedFoods
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func updateCheckbox(_ isSelected: Bool) -> UIImage{
        switch isSelected{
        case true:
            return UIImage(systemName: "checkmark.square.fill")!
        case false:
            return UIImage(systemName: "rectangle")!
        }
    }
    
    // VIEWS
    
    func setupSearchTextField() {
        self.searchTextField.searchResultsUpdater = self
        self.searchTextField.obscuresBackgroundDuringPresentation = false
        self.searchTextField.hidesNavigationBarDuringPresentation = false
        self.searchTextField.searchBar.placeholder = "Search Foods"
        
        self.navigationItem.searchController = searchTextField
        self.definesPresentationContext = false
        self.navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    func setupTableView() {
        view.addSubview(tableView)
        
        tableView.frame =  CGRect(x: 0, y: 100, width:view.bounds.width, height: view.bounds.height * 0.7)
        tableView.rowHeight = 60
        tableView.register(CustomCell.self, forCellReuseIdentifier: "cell")
    }
    
    func setupButton() {
        view.addSubview(button)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.bottomAnchor.constraint(equalTo: self.view.bottomAnchor,constant: -view.bounds.height * 0.05),
            button.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            
            button.heightAnchor.constraint(equalToConstant: 50),
            button.widthAnchor.constraint(equalToConstant: self.view.bounds.width * 0.8)
        ])
        
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
    }

}

extension SelectFoodViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.inSearchMode(searchText: searchController.searchBar.text ?? "") ? viewModel.filterFoods(searchText: searchController.searchBar.text ?? "") : viewModel.fetchFoods()
        tableView.reloadData()
    }
}
extension SelectFoodViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.foods.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomCell
        let ingredient = viewModel.foods[indexPath.row]
        cell.foodName.text = ingredient.name
        cell.checkboxImageView.image = updateCheckbox(ingredient.isSelected)
        return cell
    }
}
