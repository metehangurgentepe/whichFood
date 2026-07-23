import UIKit
import Combine

/// UIKit port of `WFHomeView`.
final class WFHomeViewController: UIViewController {

    private let appState: WhichFoodAppState
    private let createFromIngredients: () -> Void
    private let createFromPhoto: () -> Void
    private let createFromPrompt: (String) -> Void
    private let openRecipe: (RecipeResponseModel) -> Void

    private var cancellables = Set<AnyCancellable>()

    private let filters = ["All", "Meaty", "Vegetarian", "Dessert"]
    private var selectedFilter = "All"

    // MARK: - UI

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()

    private let contentStack = UIStackView.wf(axis: .vertical, spacing: 20, alignment: .fill)

    private let greetingLabel: UILabel = {
        let label = UILabel()
        label.font = WFUIFont.body(13.5, weight: .semibold)
        label.textColor = WFUIPalette.secondaryText
        return label
    }()

    private let headlineLabel: UILabel = {
        let label = UILabel()
        label.text = "Let's cook something great."
        label.font = WFUIFont.heading(24, weight: .bold)
        label.textColor = WFUIPalette.text
        label.numberOfLines = 0
        return label
    }()

    private let promptField = UISearchTextField()
    private let promptSendButton = UIButton(type: .system)

    private let sectionTitleLabel = WFUISectionTitleLabel("Your recipes")

    private let savedCountLabel: UILabel = {
        let label = UILabel()
        label.font = WFUIFont.body(12.5, weight: .semibold)
        label.textColor = WFUIPalette.secondaryText
        label.textAlignment = .right
        return label
    }()

    private let filtersScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    private let filtersStack = UIStackView.wf(axis: .horizontal, spacing: 8)

    /// Rows of two recipe cards, rebuilt whenever the library changes.
    private let gridStack = UIStackView.wf(axis: .vertical, spacing: 14)

    private let emptyStateView = WFUIEmptyStateView()
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = WFUIPalette.orange
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Init

    init(
        appState: WhichFoodAppState,
        createFromIngredients: @escaping () -> Void,
        createFromPhoto: @escaping () -> Void,
        createFromPrompt: @escaping (String) -> Void,
        openRecipe: @escaping (RecipeResponseModel) -> Void
    ) {
        self.appState = appState
        self.createFromIngredients = createFromIngredients
        self.createFromPhoto = createFromPhoto
        self.createFromPrompt = createFromPrompt
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

        setupLayout()
        bindState()
        reload()
    }

    // MARK: - Setup

    private func setupLayout() {
        // Dismiss the keyboard when scrolling or tapping outside the field
        scrollView.keyboardDismissMode = .onDrag
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

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

        greetingLabel.text = greeting

        let heading = UIStackView.wf(axis: .vertical, spacing: 2, views: [greetingLabel, headlineLabel])
        contentStack.addArrangedSubview(heading)

        contentStack.addArrangedSubview(makeActionCards())
        contentStack.addArrangedSubview(makePromptField())
        contentStack.addArrangedSubview(makeRecipesSection())
    }

    private func makeActionCards() -> UIView {
        let ingredientsCard = WFUIHomeActionCard(
            title: "From Ingredients",
            subtitle: "Use what you already have",
            icon: "basket",
            accent: WFUIPalette.orange
        ) { [weak self] in self?.createFromIngredients() }

        let photoCard = WFUIHomeActionCard(
            title: "From Photo",
            subtitle: "Snap a dish, get the recipe",
            icon: "camera",
            accent: WFUIPalette.green
        ) { [weak self] in self?.createFromPhoto() }

        let row = UIStackView.wf(axis: .horizontal, spacing: 12, distribution: .fillEqually, views: [
            ingredientsCard, photoCard
        ])
        return row
    }

    /// Native search-style field (same structure as the Discover / ingredient
    /// search bars) that describes a dish for the AI to write up.
    private func makePromptField() -> UIView {
        promptField.placeholder = "Describe a dish… e.g. spicy lentil soup"
        promptField.font = WFUIFont.body(14)
        promptField.returnKeyType = .go
        promptField.delegate = self
        promptField.translatesAutoresizingMaskIntoConstraints = false
        promptField.addTarget(self, action: #selector(promptChanged), for: .editingChanged)

        // Swap the built-in magnifier for the AI sparkles glyph
        let icon = UIImageView(image: UIImage(systemName: "sparkles"))
        icon.tintColor = WFUIPalette.orange
        icon.contentMode = .center
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        promptField.leftView = icon
        promptField.leftViewMode = .always

        promptSendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        promptSendButton.tintColor = WFUIPalette.orange
        promptSendButton.setPreferredSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: 24, weight: .regular),
            forImageIn: .normal
        )
        promptSendButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        promptSendButton.addTarget(self, action: #selector(submitPrompt), for: .touchUpInside)
        promptSendButton.isEnabled = false
        promptSendButton.alpha = 0.35
        promptField.rightView = promptSendButton
        promptField.rightViewMode = .always

        NSLayoutConstraint.activate([
            promptField.heightAnchor.constraint(equalToConstant: 44)
        ])

        return promptField
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func promptChanged() {
        let hasText = !(promptField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        promptSendButton.isEnabled = hasText
        promptSendButton.alpha = hasText ? 1 : 0.35
    }

    @objc private func submitPrompt() {
        let text = (promptField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        promptField.resignFirstResponder()
        promptField.text = ""
        promptChanged()

        createFromPrompt(text)
    }

    private func makeRecipesSection() -> UIView {
        let header = UIStackView.wf(axis: .horizontal, alignment: .firstBaseline, views: [
            sectionTitleLabel, savedCountLabel
        ])
        savedCountLabel.setContentHuggingPriority(.required, for: .horizontal)

        // Full-bleed filter row: no horizontal padding, edge alignment handled
        // by contentInset so the chips scroll all the way under the screen edge.
        let filtersWrapper = UIView()
        filtersWrapper.clipsToBounds = false
        filtersWrapper.translatesAutoresizingMaskIntoConstraints = false

        filtersScrollView.clipsToBounds = false
        filtersScrollView.contentInset = UIEdgeInsets(top: 0, left: 22, bottom: 0, right: 22)
        filtersWrapper.addSubview(filtersScrollView)
        filtersScrollView.addSubview(filtersStack)

        NSLayoutConstraint.activate([
            // Break out of the section's 22pt padding back to the full width
            filtersScrollView.leadingAnchor.constraint(equalTo: filtersWrapper.leadingAnchor, constant: -22),
            filtersScrollView.trailingAnchor.constraint(equalTo: filtersWrapper.trailingAnchor, constant: 22),
            filtersScrollView.topAnchor.constraint(equalTo: filtersWrapper.topAnchor),
            filtersScrollView.bottomAnchor.constraint(equalTo: filtersWrapper.bottomAnchor),
            filtersWrapper.heightAnchor.constraint(equalToConstant: 38),

            filtersStack.topAnchor.constraint(equalTo: filtersScrollView.topAnchor),
            filtersStack.leadingAnchor.constraint(equalTo: filtersScrollView.leadingAnchor),
            filtersStack.trailingAnchor.constraint(equalTo: filtersScrollView.trailingAnchor),
            filtersStack.bottomAnchor.constraint(equalTo: filtersScrollView.bottomAnchor),
            filtersStack.heightAnchor.constraint(equalTo: filtersScrollView.heightAnchor)
        ])

        for filter in filters {
            let chip = WFUIChipButton(title: filter)
            chip.addAction(UIAction { [weak self] _ in
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                self?.selectedFilter = filter
                self?.reload()
            }, for: .touchUpInside)
            filtersStack.addArrangedSubview(chip)
        }

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false

        let section = UIStackView.wf(axis: .vertical, spacing: 12, views: [
            header, filtersWrapper, loadingIndicator, emptyStateView, gridStack
        ])
        return section
    }

    // MARK: - State

    private func bindState() {
        // Rebuild whenever the library or favourites change
        appState.$savedRecipes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.reload() }
            .store(in: &cancellables)

        appState.$favoriteRecipes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.reload() }
            .store(in: &cancellables)

        appState.$isLoadingLibrary
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.reload() }
            .store(in: &cancellables)
    }

    private var filteredRecipes: [Recipe] {
        guard selectedFilter != "All" else { return appState.savedRecipes }

        let target: String
        switch selectedFilter {
        case "Meaty": target = "meat"
        case "Vegetarian": target = "vegetable"
        default: target = "dessert"
        }
        return appState.savedRecipes.filter { $0.type?.lowercased() == target }
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: return "Good morning"
        case 12..<18: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private func reload() {
        savedCountLabel.text = "\(appState.savedRecipes.count) saved"

        for case let chip as WFUIChipButton in filtersStack.arrangedSubviews {
            chip.setSelectedState(chip.title == selectedFilter)
        }

        let recipes = filteredRecipes
        let isLoading = appState.isLoadingLibrary && appState.savedRecipes.isEmpty

        if isLoading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }

        emptyStateView.isHidden = isLoading || !recipes.isEmpty
        if !emptyStateView.isHidden {
            emptyStateView.configure(
                icon: "fork.knife.circle",
                title: selectedFilter == "All"
                    ? "Your cookbook is empty"
                    : "No \(selectedFilter.lowercased()) recipes yet",
                message: selectedFilter == "All"
                    ? "Create a recipe from your ingredients or a food photo to get started."
                    : "Try another filter or create something new."
            )
        }

        rebuildGrid(with: recipes)
    }

    /// Two-column grid built from rows of stacked cards.
    private func rebuildGrid(with recipes: [Recipe]) {
        gridStack.arrangedSubviews.forEach {
            gridStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        gridStack.isHidden = recipes.isEmpty

        for pair in stride(from: 0, to: recipes.count, by: 2) {
            let row = UIStackView.wf(axis: .horizontal, spacing: 14, distribution: .fillEqually)

            for index in pair..<min(pair + 2, recipes.count) {
                let recipe = recipes[index]
                let response = RecipeResponseModel.fromRecipe(recipe)

                let card = WFUIRecipeCardView(
                    recipe: response,
                    isFavorite: appState.isFavorite(response),
                    toggleFavorite: { [weak self] in
                        // Persisting is async; the $favoriteRecipes subscription
                        // rebuilds the grid once it lands.
                        self?.appState.toggleFavorite(response)
                    },
                    open: { [weak self] in self?.openRecipe(response) },
                    delete: { [weak self] in
                        guard let self else { return }
                        Task { await self.appState.delete(recipe) }
                    }
                )
                row.addArrangedSubview(card)
            }

            // A lone card on the last row must not stretch to full width
            if row.arrangedSubviews.count == 1 {
                let filler = UIView()
                filler.translatesAutoresizingMaskIntoConstraints = false
                row.addArrangedSubview(filler)
            }

            gridStack.addArrangedSubview(row)
        }
    }
}

// MARK: - Prompt field

extension WFHomeViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        submitPrompt()
        return true
    }
}

// MARK: - Subviews

/// "From Ingredients" / "From Photo" entry card.
final class WFUIHomeActionCard: UIControl {
    private let action: () -> Void

    /// `accent` fills the card; both entry points are filled with their own
    /// colour so the pair reads as the app's two-colour system.
    init(title: String, subtitle: String, icon: String, accent: UIColor, action: @escaping () -> Void) {
        self.action = action
        super.init(frame: .zero)

        backgroundColor = accent
        layer.cornerRadius = 20
        layer.cornerCurve = .continuous

        let foreground = UIColor.white
        let secondary = UIColor.white.withAlphaComponent(0.85)

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = foreground
        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = WFUIFont.heading(15, weight: .bold)
        titleLabel.textColor = foreground
        titleLabel.numberOfLines = 0

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = WFUIFont.body(11.5)
        subtitleLabel.textColor = secondary
        subtitleLabel.numberOfLines = 0

        let stack = UIStackView.wf(axis: .vertical, spacing: 6, alignment: .leading, views: [
            iconView, titleLabel, subtitleLabel
        ])
        stack.isUserInteractionEnabled = false
        stack.setCustomSpacing(12, after: iconView)
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func handleTap() {
        action()
    }
}

/// Capsule filter chip (`WFChip`).
final class WFUIChipButton: UIButton {
    let title: String

    init(title: String) {
        self.title = title
        super.init(frame: .zero)

        var config = UIButton.Configuration.plain()
        config.title = title
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = WFUIFont.body(13, weight: .semibold)
            return outgoing
        }
        configuration = config

        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 38).isActive = true

        layer.cornerRadius = 19
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSelectedState(_ selected: Bool) {
        configuration?.baseForegroundColor = selected ? .white : WFUIPalette.text
        backgroundColor = selected ? WFUIPalette.dark : WFUIPalette.card
        layer.borderColor = (selected ? UIColor.clear : WFUIPalette.border).cgColor
    }
}

/// Grid card for a saved recipe.
final class WFUIRecipeCardView: UIControl {
    private let open: () -> Void
    private let toggleFavorite: () -> Void

    private let imageView = WFUIRemoteImageView(frame: .zero)
    private let favoriteButton = UIButton(type: .system)

    init(
        recipe: RecipeResponseModel,
        isFavorite: Bool,
        toggleFavorite: @escaping () -> Void,
        open: @escaping () -> Void,
        // Discover results aren't in the user's library, so they can't be deleted
        delete: (() -> Void)? = nil
    ) {
        self.open = open
        self.toggleFavorite = toggleFavorite
        super.init(frame: .zero)

        backgroundColor = WFUIPalette.card
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = WFUIPalette.border.cgColor
        clipsToBounds = true

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.load(urlString: recipe.imageURL)

        // Solid translucent disc. A UIVisualEffectView added *inside* the button
        // fights UIButton's own subview management and can end up covering the
        // glyph, so keep the background on the button itself.
        favoriteButton.setImage(UIImage(systemName: isFavorite ? "heart.fill" : "heart"), for: .normal)
        favoriteButton.tintColor = isFavorite ? WFUIPalette.orange : WFUIPalette.onPhotoChipText
        favoriteButton.setPreferredSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold),
            forImageIn: .normal
        )
        favoriteButton.backgroundColor = WFUIPalette.onPhotoChip
        favoriteButton.layer.cornerRadius = 16
        favoriteButton.layer.shadowColor = UIColor.black.cgColor
        favoriteButton.layer.shadowOpacity = 0.15
        favoriteButton.layer.shadowRadius = 5
        favoriteButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        favoriteButton.addTarget(self, action: #selector(handleFavorite), for: .touchUpInside)

        let titleLabel = UILabel()
        titleLabel.text = recipe.foodName
        titleLabel.font = WFUIFont.heading(13.5, weight: .bold)
        titleLabel.textColor = WFUIPalette.text
        titleLabel.numberOfLines = 2

        let timeLabel = UILabel()
        timeLabel.text = recipe.totalTime ?? recipe.cookTime
        timeLabel.font = WFUIFont.body(11.5)
        timeLabel.textColor = WFUIPalette.secondaryText

        let textStack = UIStackView.wf(axis: .vertical, spacing: 3, alignment: .leading, views: [
            titleLabel, timeLabel
        ])
        textStack.isUserInteractionEnabled = false

        addSubview(imageView)
        addSubview(favoriteButton)
        addSubview(textStack)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 0.72),

            favoriteButton.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            favoriteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            favoriteButton.widthAnchor.constraint(equalToConstant: 32),
            favoriteButton.heightAnchor.constraint(equalToConstant: 32),

            textStack.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
            textStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])

        addTarget(self, action: #selector(handleOpen), for: .touchUpInside)

        self.delete = delete
        if delete != nil {
            // Long press to delete, matching the SwiftUI context menu
            addInteraction(UIContextMenuInteraction(delegate: self))
        }
    }

    private var delete: (() -> Void)?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previous) else { return }
        // CGColor is frozen at its resolved value, so refresh it on theme change
        layer.borderColor = WFUIPalette.border.cgColor
    }

    @objc private func handleOpen() {
        open()
    }

    @objc private func handleFavorite() {
        toggleFavorite()
    }
}

extension WFUIRecipeCardView {
    override func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let delete = UIAction(
                title: "Delete",
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { _ in
                self?.delete?()
            }
            return UIMenu(children: [delete])
        }
    }
}

/// Dashed empty-state panel.
final class WFUIEmptyStateView: UIView {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()

    init() {
        super.init(frame: .zero)

        let border = CAShapeLayer()
        border.strokeColor = WFUIPalette.border.cgColor
        border.fillColor = UIColor.clear.cgColor
        border.lineDashPattern = [6, 5]
        border.lineWidth = 1.5
        layer.addSublayer(border)
        dashedBorder = border

        iconView.tintColor = WFUIPalette.tertiaryText
        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 34, weight: .regular)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.heightAnchor.constraint(equalToConstant: 38).isActive = true

        titleLabel.font = WFUIFont.heading(15, weight: .bold)
        titleLabel.textColor = WFUIPalette.text
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        messageLabel.font = WFUIFont.body(12.5)
        messageLabel.textColor = WFUIPalette.secondaryText
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        let stack = UIStackView.wf(axis: .vertical, spacing: 8, alignment: .center, views: [
            iconView, titleLabel, messageLabel
        ])
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 28),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -28)
        ])
    }

    private var dashedBorder: CAShapeLayer?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        dashedBorder?.frame = bounds
        dashedBorder?.path = UIBezierPath(roundedRect: bounds, cornerRadius: 18).cgPath
    }

    func configure(icon: String, title: String, message: String) {
        iconView.image = UIImage(systemName: icon)
        titleLabel.text = title
        messageLabel.text = message
    }
}
