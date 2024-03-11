//
//  FavoritesVC.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 6.03.2024.
//

import UIKit

class FavoriteViewController: DataLoadingVC {
    enum Section {
        case main
    }
    
    var collectionView: UICollectionView!
    var recipes: [Recipe] = []
    var dataSource: UICollectionViewDiffableDataSource<Section, Recipe>!
    var filteredRecipes: [Recipe] = []
    var viewModel = FavoriteViewModel()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
        viewModel.load()
        configureViewController()
        configureCollectionView()
        configureDataSource()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.load()
    }
    
    
    func configureViewController() {
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        title = LocaleKeys.Home.favorites.rawValue.locale()
    }
    
    
    func configureCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: UIHelper.createThreeColumntFlowLayout(in: view))
        view.addSubview(collectionView)
        collectionView.delegate = self
        collectionView.backgroundColor = .systemBackground
        collectionView.register(FavoriteMovieCell.self, forCellWithReuseIdentifier: FavoriteMovieCell.identifier)
    }
    
    
    func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { collectionView, indexPath, recipe in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FavoriteMovieCell.identifier, for: indexPath) as! FavoriteMovieCell
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

extension FavoriteViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.delegate?.handleOutput(.selectMovie(indexPath.row))
    }
}


extension FavoriteViewController: FavoriteViewModelDelegate {
    func navigate(to navigationType: NavigationType) {
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
    
    func handleOutput(_ output: FavoriteViewModelOutput) {
        switch output {
        case .favoriteList(let recipes):
            self.recipes = recipes
            updatedData(on: self.recipes)
            
        case .error(let error):
            presentAlertOnMainThread(title: "Error", message: error.localizedDescription, buttonTitle: "Ok")
            
        case .selectMovie(let id):
            let recipe = recipes[id]
            let viewModel = DetailRecipeViewModel(recipe: recipe)
            let viewController = DetailRecipeBuilder.make(with: viewModel)
            show(viewController, sender: nil)
            
        case .showEmptyView:
            DispatchQueue.main.async{
                self.showEmptyStateView(with: LocaleKeys.Home.noItem.rawValue.locale(), in: self.collectionView)
            }
        }
    }
}
