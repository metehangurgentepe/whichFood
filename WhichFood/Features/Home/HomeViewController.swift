//
//  HomeViewController.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 11.09.2023.
//

import UIKit
import FirebaseFirestore

class HomeViewController: UIViewController {
    
    
    let nextButton = UIButton()
    let tableView = UITableView()
    let loadingIndicator = UIActivityIndicatorView()
    let noItemLabel = UILabel()
    var isLoadingIndicator: Bool = false
    
    private let viewModel = HomeViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = .systemBackground
        title = "Tarifler"
        
        setUpButton()
        setupRecipeTable()
        setupLabel()
        setupIndicator()
        settingsButton()
        
        
        viewModel.delegate = self
        viewModel.getRecipes()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func settingsButton() {
        let button = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(goToSettings))
        navigationItem.rightBarButtonItem = button
    }
    
    @objc func goToSettings() {
        let vc = SettingsVC()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func setupLabel() {
        self.view.addSubview(noItemLabel)
        noItemLabel.text = "There is no recipes for you"
        noItemLabel.textColor = .gray.withAlphaComponent(0.3)
        noItemLabel.isHidden = true
        noItemLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            noItemLabel.topAnchor.constraint(equalTo: self.view.topAnchor,constant: view.bounds.height * 0.15),
            noItemLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor)
        ])
    }
    
    func setupIndicator() {
        view.addSubview(loadingIndicator)
        loadingIndicator.isHidden = isLoadingIndicator
        loadingIndicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        
    }
    
    func setupRecipeTable() {
        view.addSubview(tableView)
        tableView.frame =  CGRect(x: 0, y: 100, width:view.bounds.width, height: view.bounds.height * 0.74)
        tableView.rowHeight = view.bounds.height * 0.1
        tableView.separatorStyle = .none
        tableView.separatorInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        
        tableView.register(RecipeCell.self, forCellReuseIdentifier: "recipeCell")
     //   tableView.allowsSelection = false
    }
    
    func setUpButton(){
        nextButton.backgroundColor = Colors.primary.color
        nextButton.setTitle("Create new recipe", for: .normal)
        
        nextButton.layer.cornerRadius = 12
        self.view.addSubview(nextButton)
        
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nextButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            nextButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor,constant: -view.bounds.height * 0.06),
            
            nextButton.heightAnchor.constraint(equalToConstant: view.bounds.height * 0.07),
            nextButton.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.85)
        ])
        
        nextButton.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
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
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.recipes.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = DetailRecipeVC()
        let recipe = viewModel.recipes[indexPath.row]
        vc.recipe = recipe
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recipeCell", for: indexPath) as! RecipeCell
        let recipe = viewModel.recipes[indexPath.row]
        cell.foodName.text = recipe.name
        cell.createdTime.text = viewModel.formatDate(recipe.createdAt.dateValue().description)
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            let id = viewModel.recipes[indexPath.row].id
            print(id)
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

extension HomeViewController: HomeViewModelDelegate {
    func isLoading() {
        isLoadingIndicator = true
    }
    
    func didFinish() {
        tableView.reloadData()
        isLoadingIndicator = false
    }
    
    func didFail(error: Error) {
        print(error)
    }
}
