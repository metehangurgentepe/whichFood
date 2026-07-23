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
    let searchController = UISearchController()

    private lazy var languageFilterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(getCurrentLanguageFlag(), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(languageFilterTapped), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.delegate = self
        viewModel.load()

        configureViewController()
        configureSearchController()
        configureNavBar()
        configureCollectionView()
        configureDataSource()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // when scroll keyboard close
        searchController.searchBar.searchTextField.resignFirstResponder()
    }
    
    func configureViewController() {
        view.backgroundColor = .systemBackground
        title = LocaleKeys.Home.search.rawValue.locale()
    }

    func configureNavBar() {
        languageFilterButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
        languageFilterButton.heightAnchor.constraint(equalToConstant: 32).isActive = true

        let barButtonItem = UIBarButtonItem(customView: languageFilterButton)
        navigationItem.rightBarButtonItem = barButtonItem
    }
    
    func configureSearchController() {
        
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = LocaleKeys.Home.search.rawValue.locale()
        searchController.searchBar.tintColor = Colors.accent.color
        searchController.searchBar.searchTextField.leftView?.tintColor = Colors.accent.color
        navigationItem.searchController = searchController
    }
    
    func configureCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: createTwoColumnFlowLayout(in: view))
        view.addSubview(collectionView)
        collectionView.delegate = self
        collectionView.backgroundColor = .systemBackground
        collectionView.register(SearchCell.self, forCellWithReuseIdentifier: SearchCell.identifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { collectionView, indexPath, recipe in
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
        DispatchQueue.main.async {
            self.dataSource.apply(snapshot, animatingDifferences: true)
        }
    }
    
    private func createTwoColumnFlowLayout(in view: UIView) -> UICollectionViewFlowLayout {
        let width = view.bounds.width
        let padding: CGFloat = 12 // Reduced from 16 to 12
        let minimumItemSpacing: CGFloat = 8 // Reduced from 16 to 8
        let availableWidth = width - (padding * 2) - minimumItemSpacing
        let itemWidth = availableWidth / 2
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        flowLayout.itemSize = CGSize(width: itemWidth, height: itemWidth + 80) // Reduced height
        flowLayout.minimumLineSpacing = 12 // Reduced from 24 to 12
        flowLayout.minimumInteritemSpacing = minimumItemSpacing
        
        return flowLayout
    }
}

extension SearchViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.delegate?.navigate(to: .details(indexPath.row))
    }
}

// MARK: - Language Filter Functions
extension SearchViewController {
    @objc private func languageFilterTapped() {
        let alertController = UIAlertController(title: "Filter by Language", message: "Select recipes by language", preferredStyle: .actionSheet)

        let languages = [
            ("🇺🇸", "English", "en"),
            ("🇹🇷", "Türkçe", "tr"),
            ("🇩🇪", "Deutsch", "de"),
            ("🇫🇷", "Français", "fr"),
            ("🇪🇸", "Español", "es"),
            ("🇮🇹", "Italiano", "it"),
            ("🌍", "All Languages", "all")
        ]

        for (flag, name, code) in languages {
            let action = UIAlertAction(title: "\(flag) \(name)", style: .default) { [weak self] _ in
                self?.filterRecipesByLanguage(code)
                self?.languageFilterButton.setTitle(flag, for: .normal)
            }
            alertController.addAction(action)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)

        if let popover = alertController.popoverPresentationController {
            popover.sourceView = languageFilterButton
            popover.sourceRect = languageFilterButton.bounds
        }

        present(alertController, animated: true)
    }

    private func getCurrentLanguageFlag() -> String {
        let currentLanguage = Bundle.main.preferredLocalizations.first ?? "en"
        switch currentLanguage {
        case "tr": return "🇹🇷"
        case "de": return "🇩🇪"
        case "fr": return "🇫🇷"
        case "es": return "🇪🇸"
        case "it": return "🇮🇹"
        case "ar": return "🇸🇦"
        case "ru": return "🇷🇺"
        case "zh-Hans": return "🇨🇳"
        case "ja": return "🇯🇵"
        case "ko": return "🇰🇷"
        case "pt": return "🇵🇹"
        case "nl": return "🇳🇱"
        case "cs": return "🇨🇿"
        case "hr": return "🇭🇷"
        case "fi": return "🇫🇮"
        case "fa": return "🇮🇷"
        default: return "🇺🇸"
        }
    }

    private func filterRecipesByLanguage(_ languageCode: String) {
        if languageCode == "all" {
            // Show all recipes
            viewModel.load()
        } else {
            // Filter recipes by language (this would need backend support)
            // For now, we'll reload with current language
            viewModel.loadRecipesByLanguage(languageCode)
        }
    }
}

extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let filter = searchController.searchBar.text ?? ""
        if filter.isEmpty {
            self.dismissLoadingView()
            viewModel.load()
        } else {
            viewModel.search(filter: filter)
        }
    }
}

extension SearchViewController: SearchViewModelDelegate {
    func handleOutput(_ output: SearchViewModelOutput) {
        switch output {
        case .getRecipeBySearch(let recipes):
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.recipes = recipes
                self.updatedData(on: recipes)
                self.dismissLoadingView()
            }
            
        case .loadRecipes(let recipes):
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.recipes = recipes
                self.updatedData(on: recipes)
                self.dismissLoadingView()
            }
            
        case .setLoading(let isLoading):
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if isLoading {
                    self.customLoadingView()
                } else {
                    self.dismissLoadingView()
                }
            }
            
        case .error(let error):
            DispatchQueue.main.async { [weak self] in
                self?.dismissLoadingView()
                self?.presentAlertOnMainThread(title: "Error", message: error.localizedDescription, buttonTitle: "Ok")
            }
        }
    }
    
    func navigate(to navigationType: NavigationType) {
        switch navigationType {
        case .details(let index):
            let vc = ShowFoodVC()
            vc.mode = .detail
            vc.recipe = self.recipes[index].toRecipeResponseModel()
            self.navigationController?.pushViewController(vc, animated: true)
            
        case .goToVC(_):
            break
            
        case .present(_):
            break
        }
    }
}
