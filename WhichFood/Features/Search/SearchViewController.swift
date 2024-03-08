//
//  SearchVC.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 6.03.2024.
//

import UIKit

class SearchViewController: UIViewController {
    
    var movies: [Movie] = []
    var filteredMovie: [Movie] = []
    var collectionView: UICollectionView!
    var page: Int = 1
    var dataSource: UICollectionViewDiffableDataSource<Section, Movie>!

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
        searchController.searchBar.placeholder = "Search for a movie"
        navigationItem.searchController = searchController
    }
    
    
    func configureCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: UIHelper.createThreeColumntFlowLayout(in: view))
        view.addSubview(collectionView)
        collectionView.delegate = self
        collectionView.backgroundColor = .systemBackground
        collectionView.register(SeeAllCell.self, forCellWithReuseIdentifier: SeeAllCell.identifier)
    }
    
    func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { collectionView, indexPath, follower in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SeeAllCell.identifier, for: indexPath) as! SeeAllCell
            let movie = self.movies[indexPath.row]
            cell.set(movie: movie)
            return cell
        })
    }
    
    func updatedData(on movies: [Movie]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Movie>()
        snapshot.appendSections([.main])
        snapshot.appendItems(movies)
        DispatchQueue.main.async{
            self.dataSource.apply(snapshot,animatingDifferences: true)
        }
    }

}

extension SearchViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let movieId = movies[indexPath.row].id
        viewModel.delegate?.handleOutput(.selectMovie(movieId))
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
        case .getMoviesBySearch(let movies):
            DispatchQueue.main.async{ [weak self] in
                guard let self = self else { return }
                self.movies = movies
                self.updatedData(on: movies)
            }
        case .loadMovies(let movies):
            DispatchQueue.main.async{ [weak self] in
                guard let self = self else { return }
                self.movies = movies
                self.updatedData(on: movies)
            }
        case .setLoading(let bool):
            switch bool {
            case true:
                showLoadingView()
            case false:
                dismissLoadingView()
            }
        case .selectMovie(let id):
            let destVC = MovieDetailVC(id: id)
            navigationController?.pushViewController(destVC, animated: true)
            
        case .error(let error):
            presentAlertOnMainThread(title: "Error", message: error.localizedDescription, buttonTitle: "Ok")
        }
    }
}
