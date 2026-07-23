import UIKit
import SwiftUI

/// UIKit host for recipe creation. Being a real `UINavigationController` means
/// the ingredient flow gets the system back button and swipe-back gesture
/// instead of hand-drawn chevrons.
final class WFCreationFlowController: UINavigationController {

    private let appState: WhichFoodAppState
    private let mode: WFRecipeCreationMode

    private var preferences = Set<String>()
    private var selectedIngredientNames = Set<String>()

    init(mode: WFRecipeCreationMode, appState: WhichFoodAppState) {
        self.mode = mode
        self.appState = appState
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = WFUIPalette.background
        configureNavigationBarAppearance()

        switch mode {
        case .ingredients:
            let preferencesVC = WFPreferencesViewController(
                selected: preferences,
                onChange: { [weak self] in self?.preferences = $0 },
                next: { [weak self] in self?.showIngredientSelection() }
            )
            preferencesVC.navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .cancel,
                target: self,
                action: #selector(cancelFlow)
            )
            viewControllers = [preferencesVC]

        case .photo(let image):
            viewControllers = [makeLoadingViewController(mode: .photo)]
            generate(from: image)

        case .prompt(let text):
            viewControllers = [makeLoadingViewController(mode: .ingredients)]
            generate(fromDescription: text)
        }
    }

    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [
            .foregroundColor: WFUIPalette.text,
            .font: WFUIFont.heading(16, weight: .bold)
        ]

        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.tintColor = WFUIPalette.text
    }

    // MARK: - Steps

    private func showIngredientSelection() {
        let selectionVC = WFIngredientSelectionViewController(
            selectedNames: selectedIngredientNames,
            onChange: { [weak self] in self?.selectedIngredientNames = $0 },
            review: { [weak self] in self?.showReview() },
            generate: { [weak self] in self?.generateFromIngredients() }
        )
        pushViewController(selectionVC, animated: true)
    }

    private func showReview() {
        let sheet = WFSelectedIngredientsSheetViewController(
            selectedNames: selectedIngredientNames,
            onChange: { [weak self] names in
                self?.selectedIngredientNames = names
                // Keep the selection screen in sync behind the sheet
                if let selection = self?.topViewController as? WFIngredientSelectionViewController {
                    selection.updateSelection(names)
                }
            },
            generate: { [weak self] in self?.generateFromIngredients() }
        )
        sheet.modalPresentationStyle = .pageSheet
        if let presentation = sheet.sheetPresentationController {
            presentation.detents = [.medium(), .large()]
            presentation.prefersGrabberVisible = true
        }
        present(sheet, animated: true)
    }

    private func makeLoadingViewController(mode: WFGenerationLoadingView.Mode) -> UIViewController {
        // Loading animation is still SwiftUI
        let host = UIHostingController(rootView: WFGenerationLoadingView(mode: mode))
        host.navigationItem.hidesBackButton = true
        return host
    }

    // MARK: - Generation

    private func generateFromIngredients() {
        // May be triggered from the review sheet or straight from the bar
        guard presentedViewController != nil else {
            startIngredientGeneration()
            return
        }

        dismiss(animated: true) { [weak self] in
            self?.startIngredientGeneration()
        }
    }

    private func startIngredientGeneration() {
        pushViewController(makeLoadingViewController(mode: .ingredients), animated: true)

        Task { @MainActor in
            let ingredients = Ingredient.allIngredients()
                .filter { self.selectedIngredientNames.contains($0.name) }
            let recipe = await self.appState.generateRecipe(
                ingredients: ingredients,
                preferences: Array(self.preferences)
            )
            self.handle(recipe)
        }
    }

    private func generate(from image: UIImage) {
        Task { @MainActor in
            let recipe = await appState.generateRecipe(from: image)
            handle(recipe)
        }
    }

    private func generate(fromDescription text: String) {
        Task { @MainActor in
            let recipe = await appState.generateRecipe(fromDescription: text)
            handle(recipe)
        }
    }

    @MainActor
    private func handle(_ recipe: RecipeResponseModel?) {
        guard let recipe else {
            // Free-tier limit reached → sell premium instead of showing an error
            if appState.hitUsageLimit {
                appState.hitUsageLimit = false
                appState.errorMessage = nil
                presentPaywall()
            } else {
                showFailure()
            }
            return
        }

        let detail = WFRecipeDetailViewController(
            recipe: recipe,
            isSaved: false,
            appState: appState,
            close: { [weak self] in self?.finish() }
        )
        detail.navigationItem.hidesBackButton = true
        setViewControllers([detail], animated: true)
    }

    private func presentPaywall() {
        // Paywall is still SwiftUI; it dismisses itself via @Environment(\.dismiss).
        let paywall = UIHostingController(rootView: SubscriptionView())
        paywall.modalPresentationStyle = .fullScreen
        present(paywall, animated: true) { [weak self] in
            // Drop the loading screen underneath so dismissing the paywall
            // returns to the previous step, not a dead spinner.
            self?.popLoadingIfNeeded()
        }
    }

    private func popLoadingIfNeeded() {
        guard viewControllers.last is UIHostingController<WFGenerationLoadingView> else { return }
        if viewControllers.count > 1 {
            popViewController(animated: false)
        } else {
            // Nothing to go back to (photo/prompt entry) — close the whole flow
            finish()
        }
    }

    private func showFailure() {
        // Surface the real reason from appState rather than a generic message —
        // otherwise API-limit / network / decode failures all look identical.
        let reason = appState.errorMessage ?? "Something went wrong."
        appState.errorMessage = nil

        let alert = UIAlertController(
            title: "Couldn't create a recipe",
            message: "\(reason)\n\nWant to try again?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Try again", style: .default) { [weak self] _ in
            guard let self else { return }
            switch self.mode {
            case .ingredients: self.generateFromIngredients()
            case .photo(let image): self.generate(from: image)
            case .prompt(let text): self.generate(fromDescription: text)
            }
        })
        alert.addAction(UIAlertAction(title: "Close", style: .cancel) { [weak self] _ in
            self?.finish()
        })
        present(alert, animated: true)
    }

    @objc private func cancelFlow() {
        finish()
    }

    private func finish() {
        presentingViewController?.dismiss(animated: true)
    }
}

// MARK: - Preferences

final class WFPreferencesViewController: UIViewController {

    private var selected: Set<String>
    private let onChange: (Set<String>) -> Void
    private let onNext: () -> Void

    private let options = [
        "Easy", "Medium", "Difficult", "Healthy", "Vegan", "Vegetarian",
        "Breakfast", "Lunch", "Dinner", "Dessert", "Hearty"
    ]

    private let wrapView = WFUIWrapView()

    init(selected: Set<String>, onChange: @escaping (Set<String>) -> Void, next: @escaping () -> Void) {
        self.selected = selected
        self.onChange = onChange
        self.onNext = next
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = WFUIPalette.background

        let titleLabel = UILabel()
        titleLabel.text = "What are you in the mood for?"
        titleLabel.font = WFUIFont.heading(25, weight: .bold)
        titleLabel.textColor = WFUIPalette.text
        titleLabel.numberOfLines = 0

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Pick as many as you like — we'll shape the recipe around them."
        subtitleLabel.font = WFUIFont.body(14)
        subtitleLabel.textColor = WFUIPalette.secondaryText
        subtitleLabel.numberOfLines = 0

        wrapView.translatesAutoresizingMaskIntoConstraints = false
        wrapView.setItems(options.map(makeOptionButton))

        let button = WFUIPrimaryButton(title: "Choose ingredients")
        button.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView.wf(axis: .vertical, spacing: 8, alignment: .fill, views: [
            titleLabel, subtitleLabel, wrapView
        ])
        stack.setCustomSpacing(24, after: subtitleLabel)

        view.addSubview(stack)
        view.addSubview(button)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30)
        ])
    }

    private func makeOptionButton(_ option: String) -> UIView {
        let button = WFUIPillButton(title: option)
        button.setSelectedState(selected.contains(option))
        button.addAction(UIAction { [weak self, weak button] _ in
            guard let self, let button else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()

            if self.selected.contains(option) {
                self.selected.remove(option)
            } else {
                self.selected.insert(option)
            }
            button.setSelectedState(self.selected.contains(option))
            self.onChange(self.selected)
        }, for: .touchUpInside)
        return button
    }

    @objc private func handleNext() {
        onNext()
    }
}

// MARK: - Ingredient selection

final class WFIngredientSelectionViewController: UIViewController {

    private var selectedNames: Set<String>
    private let onChange: (Set<String>) -> Void
    private let review: () -> Void

    private let categories: [CategoryModel] = [.vegetable, .meat, .dairy, .grain, .fruit, .seafood, .herb, .nut]
    private var activeCategory: CategoryModel = .vegetable
    private var query = ""

    private let searchController = UISearchController(searchResultsController: nil)
    private let categoriesScrollView = UIScrollView()
    private let categoriesStack = UIStackView.wf(axis: .horizontal, spacing: 8)
    private let scrollView = UIScrollView()
    private let listCard = WFUICardView()
    private let rowsStack = UIStackView.wf(axis: .vertical, spacing: 0)
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.font = WFUIFont.body(13.5)
        label.textColor = WFUIPalette.secondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "No ingredients match that search."
        label.isHidden = true
        return label
    }()
    private let reviewBar = WFUIReviewBarView()

    private var reviewBarBottomConstraint: NSLayoutConstraint?

    private let generate: () -> Void

    init(
        selectedNames: Set<String>,
        onChange: @escaping (Set<String>) -> Void,
        review: @escaping () -> Void,
        generate: @escaping () -> Void
    ) {
        self.selectedNames = selectedNames
        self.onChange = onChange
        self.review = review
        self.generate = generate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = WFUIPalette.background
        title = "What's in your kitchen?"

        setupSearchController()
        setupLayout()
        rebuildCategories()
        rebuildIngredients()
        updateReviewBar(animated: false)
    }

    /// Called when the review sheet removes ingredients behind our back.
    func updateSelection(_ names: Set<String>) {
        selectedNames = names
        rebuildIngredients()
        updateReviewBar(animated: true)
    }

    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search ingredients"

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func setupLayout() {
        categoriesScrollView.translatesAutoresizingMaskIntoConstraints = false
        categoriesScrollView.showsHorizontalScrollIndicator = false
        categoriesScrollView.addSubview(categoriesStack)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false

        listCard.translatesAutoresizingMaskIntoConstraints = false
        listCard.addSubview(rowsStack)
        NSLayoutConstraint.activate([
            rowsStack.topAnchor.constraint(equalTo: listCard.topAnchor),
            rowsStack.leadingAnchor.constraint(equalTo: listCard.leadingAnchor),
            rowsStack.trailingAnchor.constraint(equalTo: listCard.trailingAnchor),
            rowsStack.bottomAnchor.constraint(equalTo: listCard.bottomAnchor)
        ])

        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(listCard)
        scrollView.addSubview(emptyLabel)

        reviewBar.translatesAutoresizingMaskIntoConstraints = false
        reviewBar.addTarget(self, action: #selector(handleReview), for: .touchUpInside)
        reviewBar.onGenerate = { [weak self] in self?.generate() }

        view.addSubview(categoriesScrollView)
        view.addSubview(scrollView)
        view.addSubview(reviewBar)

        let bottom = reviewBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        reviewBarBottomConstraint = bottom

        NSLayoutConstraint.activate([
            categoriesScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            categoriesScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoriesScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            categoriesScrollView.heightAnchor.constraint(equalToConstant: 38),

            categoriesStack.topAnchor.constraint(equalTo: categoriesScrollView.topAnchor),
            categoriesStack.bottomAnchor.constraint(equalTo: categoriesScrollView.bottomAnchor),
            categoriesStack.leadingAnchor.constraint(equalTo: categoriesScrollView.leadingAnchor, constant: 24),
            categoriesStack.trailingAnchor.constraint(equalTo: categoriesScrollView.trailingAnchor, constant: -24),
            categoriesStack.heightAnchor.constraint(equalTo: categoriesScrollView.heightAnchor),

            scrollView.topAnchor.constraint(equalTo: categoriesScrollView.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            listCard.topAnchor.constraint(equalTo: scrollView.topAnchor),
            listCard.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 24),
            listCard.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -24),
            listCard.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -108),
            listCard.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -48),

            emptyLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 40),
            emptyLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 40),
            emptyLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -40),

            reviewBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            reviewBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            reviewBar.heightAnchor.constraint(equalToConstant: 68),
            bottom
        ])
    }

    private func rebuildCategories() {
        categoriesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for category in categories {
            let chip = WFUIChipButton(title: category.localizedValue)
            chip.setSelectedState(category == activeCategory)
            chip.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                self.activeCategory = category
                self.rebuildCategories()
                self.rebuildIngredients()
            }, for: .touchUpInside)
            categoriesStack.addArrangedSubview(chip)
        }
    }

    private var visibleIngredients: [Ingredient] {
        let all = Ingredient.allIngredients()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        let matching = trimmed.isEmpty
            ? all.filter { $0.category == activeCategory }
            : all.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }

        var seen = Set<String>()
        return matching.filter { seen.insert($0.name).inserted }
    }

    private func rebuildIngredients() {
        rowsStack.arrangedSubviews.forEach {
            rowsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let ingredients = visibleIngredients
        emptyLabel.isHidden = !ingredients.isEmpty
        listCard.isHidden = ingredients.isEmpty

        for (index, ingredient) in ingredients.enumerated() {
            if index > 0 {
                rowsStack.addArrangedSubview(makeDivider())
            }

            let row = WFUIIngredientPickRowView(name: ingredient.name)
            row.setSelectedState(selectedNames.contains(ingredient.name))
            row.onTap = { [weak self, weak row] in
                guard let self, let row else { return }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()

                if self.selectedNames.contains(ingredient.name) {
                    self.selectedNames.remove(ingredient.name)
                } else {
                    self.selectedNames.insert(ingredient.name)
                }
                row.setSelectedState(self.selectedNames.contains(ingredient.name))
                self.onChange(self.selectedNames)
                self.updateReviewBar(animated: true)
            }
            rowsStack.addArrangedSubview(row)
        }
    }

    private func makeDivider() -> UIView {
        let wrapper = UIView()
        let divider = UIView()
        divider.backgroundColor = WFUIPalette.divider
        divider.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(divider)

        NSLayoutConstraint.activate([
            divider.heightAnchor.constraint(equalToConstant: 1),
            divider.topAnchor.constraint(equalTo: wrapper.topAnchor),
            divider.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
            divider.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 16),
            divider.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor)
        ])
        return wrapper
    }

    private func updateReviewBar(animated: Bool) {
        let hidden = selectedNames.isEmpty
        reviewBar.setCount(selectedNames.count)

        let apply = {
            self.reviewBar.alpha = hidden ? 0 : 1
            self.reviewBarBottomConstraint?.constant = hidden ? 120 : -12
            self.view.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) { apply() }
        } else {
            apply()
        }
        reviewBar.isUserInteractionEnabled = !hidden
    }

    @objc private func handleReview() {
        review()
    }
}

extension WFIngredientSelectionViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        query = searchController.searchBar.text ?? ""

        // Category filter is meaningless while a search is active
        categoriesScrollView.isHidden = !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        rebuildIngredients()
    }
}

// MARK: - Review sheet

final class WFSelectedIngredientsSheetViewController: UIViewController {

    private var selectedNames: Set<String>
    private let onChange: (Set<String>) -> Void
    private let generate: () -> Void

    private let wrapView = WFUIWrapView()

    init(selectedNames: Set<String>, onChange: @escaping (Set<String>) -> Void, generate: @escaping () -> Void) {
        self.selectedNames = selectedNames
        self.onChange = onChange
        self.generate = generate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = WFUIPalette.background

        let titleLabel = UILabel()
        titleLabel.text = "Your ingredients"
        titleLabel.font = WFUIFont.heading(20, weight: .bold)
        titleLabel.textColor = WFUIPalette.text

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Tap one to remove it."
        subtitleLabel.font = WFUIFont.body(13)
        subtitleLabel.textColor = WFUIPalette.secondaryText

        wrapView.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(wrapView)

        let generateButton = WFUIPrimaryButton(title: "Generate recipe")
        generateButton.translatesAutoresizingMaskIntoConstraints = false
        generateButton.addTarget(self, action: #selector(handleGenerate), for: .touchUpInside)

        let header = UIStackView.wf(axis: .vertical, spacing: 4, views: [titleLabel, subtitleLabel])
        view.addSubview(header)
        view.addSubview(scrollView)
        view.addSubview(generateButton)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 22),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            scrollView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 18),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: generateButton.topAnchor, constant: -16),

            wrapView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            wrapView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 24),
            wrapView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -24),
            wrapView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            wrapView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -48),

            generateButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            generateButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            generateButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])

        rebuild()
    }

    private func rebuild() {
        let items = selectedNames.sorted().map { name -> UIView in
            let button = WFUIPillButton(title: name, showsCheckmark: false, showsRemoveIcon: true)
            button.setSelectedState(true)
            button.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                self.selectedNames.remove(name)
                self.onChange(self.selectedNames)
                self.rebuild()

                if self.selectedNames.isEmpty {
                    self.dismiss(animated: true)
                }
            }, for: .touchUpInside)
            return button
        }
        wrapView.setItems(items)
    }

    @objc private func handleGenerate() {
        generate()
    }
}

// MARK: - Shared pieces

/// A single selectable ingredient row — name on the left, checkbox on the right.
/// Reads far better than a wall of capsules when there are dozens of options.
final class WFUIIngredientPickRowView: UIControl {
    var onTap: (() -> Void)?

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = WFUIFont.body(14.5, weight: .semibold)
        label.textColor = WFUIPalette.text
        label.numberOfLines = 0
        return label
    }()

    private let checkbox: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 7
        view.layer.borderWidth = 1.5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let checkmark: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "checkmark"))
        imageView.tintColor = .white
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 11, weight: .bold)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    init(name: String) {
        super.init(frame: .zero)
        nameLabel.text = name

        checkbox.addSubview(checkmark)
        let row = UIStackView.wf(axis: .horizontal, spacing: 12, alignment: .center, views: [
            nameLabel, UIView(), checkbox
        ])
        row.isUserInteractionEnabled = false
        addSubview(row)

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            checkbox.widthAnchor.constraint(equalToConstant: 22),
            checkbox.heightAnchor.constraint(equalToConstant: 22),
            checkmark.centerXAnchor.constraint(equalTo: checkbox.centerXAnchor),
            checkmark.centerYAnchor.constraint(equalTo: checkbox.centerYAnchor)
        ])

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSelectedState(_ selected: Bool) {
        checkbox.backgroundColor = selected ? WFUIPalette.orange : .clear
        checkbox.layer.borderColor = (selected ? UIColor.clear : WFUIPalette.border).cgColor
        checkmark.isHidden = !selected
        nameLabel.textColor = selected ? WFUIPalette.selectedText : WFUIPalette.text
    }

    @objc private func handleTap() {
        onTap?()
    }
}

/// Capsule pill used for preferences and ingredients.
final class WFUIPillButton: UIButton {
    private let showsCheckmark: Bool
    private let showsRemoveIcon: Bool

    init(title: String, showsCheckmark: Bool = false, showsRemoveIcon: Bool = false) {
        self.showsCheckmark = showsCheckmark
        self.showsRemoveIcon = showsRemoveIcon
        super.init(frame: .zero)

        var config = UIButton.Configuration.plain()
        config.title = title
        // Height comes from these insets rather than a constraint: WFUIWrapView
        // positions items by frame, so their size must be intrinsic.
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        config.imagePadding = 7
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = WFUIFont.body(15.5, weight: .semibold)
            return outgoing
        }
        configuration = config

        layer.cornerRadius = 26
        layer.borderWidth = 1.5
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSelectedState(_ selected: Bool) {
        configuration?.baseForegroundColor = selected ? .white : WFUIPalette.text
        backgroundColor = selected ? WFUIPalette.orange : WFUIPalette.card
        layer.borderColor = (selected ? UIColor.clear : WFUIPalette.border).cgColor

        if showsRemoveIcon {
            configuration?.image = UIImage(systemName: "xmark")
        } else if showsCheckmark {
            configuration?.image = selected ? UIImage(systemName: "checkmark") : nil
        }
        configuration?.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(
            pointSize: 10, weight: .bold
        )
    }
}

/// Floating bar: tap the body to review the selection, or Generate to skip
/// straight to creating the recipe.
final class WFUIReviewBarView: UIControl {
    var onGenerate: (() -> Void)?

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = WFUIFont.heading(14, weight: .bold)
        label.textColor = .white
        return label
    }()

    private let generateButton: UIButton = {
        let button = UIButton(type: .system)

        var config = UIButton.Configuration.filled()
        config.title = "Generate"
        config.baseBackgroundColor = WFUIPalette.orange
        config.baseForegroundColor = .white
        config.background.cornerRadius = 15
        config.contentInsets = NSDirectionalEdgeInsets(top: 9, leading: 14, bottom: 9, trailing: 14)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = WFUIFont.heading(13, weight: .bold)
            return outgoing
        }
        button.configuration = config
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = WFUIPalette.dark
        layer.cornerRadius = 20
        layer.cornerCurve = .continuous
        layer.shadowColor = WFUIPalette.text.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 18
        layer.shadowOffset = CGSize(width: 0, height: 8)

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Ready to turn them into a recipe"
        subtitleLabel.font = WFUIFont.body(11.5)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.68)

        let textStack = UIStackView.wf(axis: .vertical, spacing: 2, alignment: .leading, views: [
            countLabel, subtitleLabel
        ])

        let reviewLabel = UILabel()
        reviewLabel.text = "Review"
        reviewLabel.font = WFUIFont.body(13, weight: .bold)
        reviewLabel.textColor = WFUIPalette.amber

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = WFUIPalette.amber
        chevron.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 11, weight: .bold)

        let trailingStack = UIStackView.wf(axis: .horizontal, spacing: 5, alignment: .center, views: [
            reviewLabel, chevron
        ])
        // Only the Generate button takes touches; the rest falls through to
        // this control, which opens the review sheet.
        trailingStack.isUserInteractionEnabled = false
        textStack.isUserInteractionEnabled = false

        generateButton.addTarget(self, action: #selector(handleGenerate), for: .touchUpInside)
        generateButton.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView.wf(axis: .horizontal, spacing: 12, alignment: .center, views: [
            textStack, UIView(), trailingStack, generateButton
        ])
        addSubview(row)

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14)
        ])
    }

    @objc private func handleGenerate() {
        onGenerate?()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCount(_ count: Int) {
        countLabel.text = "\(count) ingredients selected"
    }
}
