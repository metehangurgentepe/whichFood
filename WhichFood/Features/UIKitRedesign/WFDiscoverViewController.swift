import UIKit
import Combine

/// UIKit port of `WFDiscoverView`.
///
/// Shows the app's own catalogue plus, for English-language users, recipes
/// pulled from TheMealDB in a separate section.
final class WFDiscoverViewController: UIViewController {

    private let appState: WhichFoodAppState
    private let openRecipe: (RecipeResponseModel) -> Void

    private var cancellables = Set<AnyCancellable>()
    private var query = ""

    // MARK: - UI

    private let searchController = UISearchController(searchResultsController: nil)

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .onDrag
        return scrollView
    }()

    private let contentStack = UIStackView.wf(axis: .vertical, spacing: 14, alignment: .fill)

    private let ownGridStack = UIStackView.wf(axis: .vertical, spacing: 14)

    private let externalSection = UIStackView.wf(axis: .vertical, spacing: 14)
    private let externalTitleLabel = WFUISectionTitleLabel("From around the web".locale())
    private let externalGridStack = UIStackView.wf(axis: .vertical, spacing: 14)

    private let emptyStateView = WFUIEmptyStateView()

    // MARK: - Init

    init(appState: WhichFoodAppState, openRecipe: @escaping (RecipeResponseModel) -> Void) {
        self.appState = appState
        self.openRecipe = openRecipe
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = WFUIPalette.background
        title = "Discover".locale()

        setupSearchController()
        setupLayout()
        bindState()
        reload()
    }

    // MARK: - Setup

    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search recipes".locale()

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 14),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 22),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -22),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -44)
        ])

        externalSection.addArrangedSubview(externalTitleLabel)
        externalSection.addArrangedSubview(externalGridStack)

        contentStack.addArrangedSubview(emptyStateView)
        contentStack.addArrangedSubview(ownGridStack)
        contentStack.addArrangedSubview(externalSection)
    }

    private func bindState() {
        appState.$catalogRecipes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.reload() }
            .store(in: &cancellables)

        appState.$externalRecipes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.reload() }
            .store(in: &cancellables)

        appState.$favoriteRecipes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.reload() }
            .store(in: &cancellables)
    }

    // MARK: - Content

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var ownResults: [RecipeResponseModel] {
        let all = appState.catalogRecipes.map(RecipeResponseModel.fromRecipe)
        guard !trimmedQuery.isEmpty else { return all }

        return all.filter {
            $0.foodName.localizedCaseInsensitiveContains(trimmedQuery) ||
            ($0.tags ?? []).contains { $0.localizedCaseInsensitiveContains(trimmedQuery) }
        }
    }

    private var externalResults: [RecipeResponseModel] {
        guard !trimmedQuery.isEmpty else { return appState.externalRecipes }

        return appState.externalRecipes.filter {
            $0.foodName.localizedCaseInsensitiveContains(trimmedQuery) ||
            ($0.tags ?? []).contains { $0.localizedCaseInsensitiveContains(trimmedQuery) }
        }
    }

    private func reload() {
        let own = ownResults
        let external = externalResults

        rebuild(gridStack: ownGridStack, with: own)
        rebuild(gridStack: externalGridStack, with: external)

        ownGridStack.isHidden = own.isEmpty
        externalSection.isHidden = external.isEmpty

        let isEmpty = own.isEmpty && external.isEmpty
        emptyStateView.isHidden = !isEmpty
        if isEmpty {
            emptyStateView.configure(
                icon: "magnifyingglass",
                title: "Nothing found".locale(),
                message: "Try a different keyword — or create it from your ingredients instead.".locale()
            )
        }
    }

    /// Two-column grid built from rows, matching the home screen.
    private func rebuild(gridStack: UIStackView, with recipes: [RecipeResponseModel]) {
        gridStack.arrangedSubviews.forEach {
            gridStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for pair in stride(from: 0, to: recipes.count, by: 2) {
            let row = UIStackView.wf(axis: .horizontal, spacing: 14, distribution: .fillEqually)

            for index in pair..<min(pair + 2, recipes.count) {
                let recipe = recipes[index]
                let card = WFUIRecipeCardView(
                    recipe: recipe,
                    isFavorite: appState.isFavorite(recipe),
                    toggleFavorite: { [weak self] in self?.appState.toggleFavorite(recipe) },
                    open: { [weak self] in self?.openRecipe(recipe) },
                    delete: nil
                )
                row.addArrangedSubview(card)
            }

            // Keep a lone trailing card at half width
            if row.arrangedSubviews.count == 1 {
                let filler = UIView()
                filler.translatesAutoresizingMaskIntoConstraints = false
                row.addArrangedSubview(filler)
            }

            gridStack.addArrangedSubview(row)
        }
    }
}

// MARK: - Search

extension WFDiscoverViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        query = searchController.searchBar.text ?? ""
        reload()
    }
}
