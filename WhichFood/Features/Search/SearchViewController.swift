//
//  SearchVC.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 6.03.2024.
//

import UIKit

class SearchViewController: DataLoadingVC {
    
    enum Section {
        case main
    }
    
    var recipes: [Recipe] = []
    var filteredRecipe: [Recipe] = []
    var collectionView: UICollectionView!
    var page: Int = 1
    var dataSource: UICollectionViewDiffableDataSource<Section, Recipe>!
    var viewModel = SearchViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.delegate = self
        viewModel.load()
        
        configureViewController()
        configureSearchController()
        configureCollectionView()
        configureDataSource()
    }
    
    
    func configureViewController() {
        view.backgroundColor = .systemBackground
    }
    
    
    func configureSearchController() {
        let searchController = UISearchController()
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = LocaleKeys.Home.search.rawValue.locale()
        navigationItem.searchController = searchController
    }
    
    
    func configureCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: UIHelper.createThreeColumntFlowLayout(in: view))
        view.addSubview(collectionView)
        collectionView.delegate = self
        collectionView.backgroundColor = .systemBackground
        collectionView.register(SearchCell.self, forCellWithReuseIdentifier: SearchCell.identifier)
    }
    
    
    func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { collectionView, indexPath, follower in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SearchCell.identifier, for: indexPath) as! SearchCell
            let recipe = self.recipes[indexPath.row]
            cell.set(recipe: recipe)
            return cell
        })
    }
    
    
    func updatedData(on recipes: [Recipe]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Recipe>()
        snapshot.appendSections([.main])
        snapshot.appendItems(recipes)
        DispatchQueue.main.async{
            self.dataSource.apply(snapshot,animatingDifferences: true)
        }
    }
}

extension SearchViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.delegate?.navigate(to: .details(indexPath.row))
    }
}


extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let filter = searchController.searchBar.text ?? ""
        if filter.isEmpty {
            viewModel.load()
        } else {
            viewModel.search(filter: filter)
        }
    }
}


extension SearchViewController: SearchViewModelDelegate{
    func handleOutput(_ output: SearchViewModelOutput) {
        switch output {
        case .getRecipeBySearch(let recipes):
            DispatchQueue.main.async{ [weak self] in
                guard let self = self else { return }
                self.recipes = recipes
                self.updatedData(on: recipes)
            }
            
        case .loadRecipes(let recipes):
            DispatchQueue.main.async{ [weak self] in
                guard let self = self else { return }
                self.recipes = recipes
                self.updatedData(on: recipes)
            }
            
        case .setLoading(let bool):
            switch bool {
            case true:
                customLoadingView()
            case false:
                dismissLoadingView()
            }
            
        case .error(let error):
            presentAlertOnMainThread(title: "Error", message: error.localizedDescription, buttonTitle: "Ok")
        }
    }
    
    func navigate(to navigationType: NavigationType) {
        switch navigationType {
        case .details(let index):
            let recipe = recipes[index]
            let viewModel = DetailRecipeViewModel(recipe: recipe)
            let viewController = DetailRecipeBuilder.make(with: viewModel)
            show(viewController, sender: nil)
            
        case .goToVC(_):
            break
            
        case .present(_):
            break
        }
    }
}
