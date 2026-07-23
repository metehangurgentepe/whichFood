import UIKit
import SwiftUI
import Combine

/// UIKit port of `WFRecipeDetailView`.
///
/// The hero photo runs to the top of the screen (behind the notch) and the
/// navigation bar sits transparently on top of it with standard system bar
/// button items, fading into a solid bar as the content scrolls up.
final class WFRecipeDetailViewController: UIViewController {

    // MARK: - State

    private var recipe: RecipeResponseModel
    private var saved: Bool
    private let appState: WhichFoodAppState
    private let close: () -> Void

    private let baseServings: Int
    private var servings: Int
    /// Stored by ingredient text, not index, so it survives servings changes.
    private var checkedIngredients = Set<String>()
    private var cancellables = Set<AnyCancellable>()

    private let heroHeight: CGFloat = 300

    // MARK: - UI

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        // Content starts at the very top of the screen, behind the notch
        scrollView.contentInsetAdjustmentBehavior = .never
        return scrollView
    }()

    private let contentStack = UIStackView.wf(axis: .vertical, spacing: 0)

    private let heroImageView = WFUIRemoteImageView(frame: .zero)
    private let heroGradient = CAGradientLayer()
    private let heroContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = WFUIFont.heading(24, weight: .bold)
        label.textColor = WFUIPalette.text
        label.numberOfLines = 0
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = WFUIFont.body(14)
        label.textColor = WFUIPalette.secondaryText
        label.numberOfLines = 0
        return label
    }()

    private let tagsWrapView: WFUIWrapView = {
        let wrap = WFUIWrapView()
        wrap.horizontalSpacing = 7
        wrap.verticalSpacing = 7
        wrap.translatesAutoresizingMaskIntoConstraints = false
        return wrap
    }()

    private let metaStack = UIStackView.wf(axis: .horizontal, distribution: .fillEqually)
    private let servingsValueLabel = WFUIMetaItemView(label: "SERVES", value: "1")

    private let nutritionSection = UIStackView.wf(axis: .vertical, spacing: 12)
    private let ingredientsCard = WFUICardView()
    private let ingredientRowsStack = UIStackView.wf(axis: .vertical, spacing: 0)
    private let servingsCountLabel: UILabel = {
        let label = UILabel()
        label.font = WFUIFont.body(12.5, weight: .bold)
        label.textColor = WFUIPalette.text
        label.textAlignment = .center
        return label
    }()

    private let instructionsStack = UIStackView.wf(axis: .vertical, spacing: 16)
    private let saveButton = WFUIPrimaryButton(title: "Save to my recipes", systemImage: "bookmark.fill")

    private lazy var favoriteButton = UIBarButtonItem(
        image: UIImage(systemName: "heart"),
        style: .plain,
        target: self,
        action: #selector(toggleFavorite)
    )

    private lazy var shareButton = UIBarButtonItem(
        image: UIImage(systemName: "square.and.arrow.up"),
        style: .plain,
        target: self,
        action: #selector(shareRecipe)
    )

    private lazy var closeButton = UIBarButtonItem(
        image: UIImage(systemName: "chevron.left"),
        style: .plain,
        target: self,
        action: #selector(closeTapped)
    )

    // MARK: - Init

    init(recipe: RecipeResponseModel, isSaved: Bool, appState: WhichFoodAppState, close: @escaping () -> Void) {
        self.recipe = recipe
        self.saved = isSaved
        self.appState = appState
        self.close = close

        let parsed = Self.parseServings(recipe.servings)
        self.baseServings = parsed
        self.servings = parsed

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = WFUIPalette.background

        checkedIngredients = Self.loadCheckedIngredients(for: recipe)

        setupNavigationBar()
        setupLayout()
        populate()

        // toggleFavorite persists asynchronously, so the button has to follow
        // the state rather than be set optimistically at tap time.
        appState.$favoriteRecipes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateFavoriteButton() }
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNavigationBar(for: scrollView.contentOffset.y)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        heroGradient.frame = heroContainer.bounds
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        scrollView.contentOffset.y > heroFadeDistance ? .darkContent : .lightContent
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = closeButton
        navigationItem.rightBarButtonItems = [shareButton, favoriteButton]
        updateFavoriteButton()
    }

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        scrollView.delegate = self

        contentStack.addArrangedSubview(makeHero())
        contentStack.addArrangedSubview(makeBody())
    }

    private func makeHero() -> UIView {
        heroImageView.translatesAutoresizingMaskIntoConstraints = false
        heroContainer.addSubview(heroImageView)

        // A longer, multi-stop ramp; a two-stop gradient starting halfway down
        // reads as a hard band across the photo.
        heroGradient.colors = [
            UIColor.clear.cgColor,
            WFUIPalette.text.withAlphaComponent(0.18).cgColor,
            WFUIPalette.text.withAlphaComponent(0.55).cgColor
        ]
        heroGradient.locations = [0.35, 0.72, 1.0]
        heroContainer.layer.addSublayer(heroGradient)

        // Soften the bottom edge so the photo doesn't cut off against the page
        heroContainer.layer.cornerRadius = 26
        heroContainer.layer.cornerCurve = .continuous
        heroContainer.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]

        NSLayoutConstraint.activate([
            heroContainer.heightAnchor.constraint(equalToConstant: heroHeight),
            heroImageView.topAnchor.constraint(equalTo: heroContainer.topAnchor),
            heroImageView.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: heroContainer.trailingAnchor),
            heroImageView.bottomAnchor.constraint(equalTo: heroContainer.bottomAnchor)
        ])

        return heroContainer
    }

    private func makeBody() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView.wf(axis: .vertical, spacing: 0, alignment: .fill)
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -22),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -38)
        ])

        // Tags — wrap onto multiple rows instead of scrolling horizontally
        stack.addArrangedSubview(tagsWrapView)
        stack.setCustomSpacing(14, after: tagsWrapView)

        stack.addArrangedSubview(titleLabel)
        stack.setCustomSpacing(8, after: titleLabel)

        stack.addArrangedSubview(descriptionLabel)
        stack.setCustomSpacing(18, after: descriptionLabel)

        stack.addArrangedSubview(makeMetaStrip())
        stack.setCustomSpacing(22, after: metaStack.superview ?? metaStack)

        stack.addArrangedSubview(nutritionSection)
        stack.setCustomSpacing(22, after: nutritionSection)

        stack.addArrangedSubview(makeActionRow())

        stack.addArrangedSubview(makeIngredientsCard())

        let instructionsSection = UIStackView.wf(axis: .vertical, spacing: 16, views: [
            WFUISectionTitleLabel("Instructions"),
            instructionsStack
        ])
        stack.addArrangedSubview(instructionsSection)

        saveButton.addTarget(self, action: #selector(saveRecipe), for: .touchUpInside)
        stack.addArrangedSubview(saveButton)

        return container
    }

    private func makeMetaStrip() -> UIView {
        let card = WFUICardView()
        card.translatesAutoresizingMaskIntoConstraints = false

        let items = [
            WFUIMetaItemView(label: "PREP", value: recipe.prepTime ?? "—"),
            WFUIMetaItemView(label: "COOK", value: recipe.cookTime),
            servingsValueLabel,
            WFUIMetaItemView(label: "LEVEL", value: recipe.difficulty ?? "Easy")
        ]

        for (index, item) in items.enumerated() {
            if index > 0 {
                metaStack.addArrangedSubview(WFUIMetaDividerView(frame: .zero))
            }
            metaStack.addArrangedSubview(item)
        }

        // Dividers stay hairline-width; the four cells split what's left evenly
        metaStack.distribution = .fill
        metaStack.alignment = .center
        for divider in metaStack.arrangedSubviews where divider is WFUIMetaDividerView {
            divider.setContentHuggingPriority(.required, for: .horizontal)
            divider.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        for item in items.dropFirst() {
            item.widthAnchor.constraint(equalTo: items[0].widthAnchor).isActive = true
        }

        card.addSubview(metaStack)
        NSLayoutConstraint.activate([
            metaStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 15),
            metaStack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            metaStack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            metaStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -15)
        ])

        return card
    }

    private func makeActionRow() -> UIView {
        let cookButton = UIButton(type: .system)
        var cookConfig = UIButton.Configuration.filled()
        cookConfig.title = "Start cooking"
        cookConfig.image = UIImage(systemName: "play.fill")
        cookConfig.imagePadding = 8
        cookConfig.baseBackgroundColor = WFUIPalette.dark
        cookConfig.baseForegroundColor = .white
        cookConfig.background.cornerRadius = 16
        cookConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = WFUIFont.heading(14, weight: .bold)
            return outgoing
        }
        cookButton.configuration = cookConfig
        cookButton.addTarget(self, action: #selector(startCooking), for: .touchUpInside)

        let remixButton = UIButton(type: .system)
        var remixConfig = UIButton.Configuration.plain()
        remixConfig.title = "Remix"
        remixConfig.image = UIImage(systemName: "arrow.clockwise")
        remixConfig.imagePadding = 7
        remixConfig.baseForegroundColor = WFUIPalette.orange
        remixConfig.background.backgroundColor = WFUIPalette.card
        remixConfig.background.cornerRadius = 16
        remixConfig.background.strokeColor = WFUIPalette.border
        remixConfig.background.strokeWidth = 1.5
        remixConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = WFUIFont.heading(14, weight: .bold)
            return outgoing
        }
        remixButton.configuration = remixConfig
        remixButton.addTarget(self, action: #selector(showRemix), for: .touchUpInside)

        let row = UIStackView.wf(axis: .horizontal, spacing: 10, views: [cookButton, remixButton])
        NSLayoutConstraint.activate([
            cookButton.heightAnchor.constraint(equalToConstant: 52),
            remixButton.heightAnchor.constraint(equalToConstant: 52),
            remixButton.widthAnchor.constraint(equalToConstant: 116)
        ])

        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: wrapper.topAnchor),
            row.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -24)
        ])
        return wrapper
    }

    private func makeIngredientsCard() -> UIView {
        let header = UIStackView.wf(axis: .horizontal, alignment: .center)

        let title = WFUISectionTitleLabel("Ingredients")
        header.addArrangedSubview(title)

        let minusButton = UIButton(type: .system)
        minusButton.setImage(UIImage(systemName: "minus"), for: .normal)
        minusButton.tintColor = WFUIPalette.text
        minusButton.addTarget(self, action: #selector(decreaseServings), for: .touchUpInside)

        let plusButton = UIButton(type: .system)
        plusButton.setImage(UIImage(systemName: "plus"), for: .normal)
        plusButton.tintColor = WFUIPalette.text
        plusButton.addTarget(self, action: #selector(increaseServings), for: .touchUpInside)

        let stepper = UIStackView.wf(axis: .horizontal, spacing: 11, alignment: .center, views: [
            minusButton, servingsCountLabel, plusButton
        ])
        stepper.backgroundColor = WFUIPalette.background
        stepper.layer.cornerRadius = 18
        stepper.layer.borderWidth = 1
        stepper.layer.borderColor = WFUIPalette.border.cgColor
        stepper.isLayoutMarginsRelativeArrangement = true
        stepper.layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)

        NSLayoutConstraint.activate([
            stepper.heightAnchor.constraint(equalToConstant: 36),
            minusButton.widthAnchor.constraint(equalToConstant: 22),
            plusButton.widthAnchor.constraint(equalToConstant: 22),
            servingsCountLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 62)
        ])

        // The stepper keeps its size; the title takes the slack
        stepper.setContentHuggingPriority(.required, for: .horizontal)
        stepper.setContentCompressionResistancePriority(.required, for: .horizontal)
        title.setContentHuggingPriority(.defaultLow, for: .horizontal)
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        header.addArrangedSubview(stepper)

        let cardStack = UIStackView.wf(axis: .vertical, spacing: 0, views: [header, ingredientRowsStack])
        cardStack.isLayoutMarginsRelativeArrangement = true
        cardStack.layoutMargins = UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0)

        ingredientsCard.translatesAutoresizingMaskIntoConstraints = false
        ingredientsCard.addSubview(cardStack)
        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: ingredientsCard.topAnchor),
            cardStack.leadingAnchor.constraint(equalTo: ingredientsCard.leadingAnchor),
            cardStack.trailingAnchor.constraint(equalTo: ingredientsCard.trailingAnchor),
            cardStack.bottomAnchor.constraint(equalTo: ingredientsCard.bottomAnchor)
        ])

        header.isLayoutMarginsRelativeArrangement = true
        header.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 16, right: 16)

        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(ingredientsCard)
        NSLayoutConstraint.activate([
            ingredientsCard.topAnchor.constraint(equalTo: wrapper.topAnchor),
            ingredientsCard.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            ingredientsCard.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            ingredientsCard.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -26)
        ])
        return wrapper
    }

    // MARK: - Content

    private func populate() {
        heroImageView.load(urlString: recipe.imageURL)

        titleLabel.text = recipe.foodName
        descriptionLabel.text = recipe.description
        descriptionLabel.isHidden = recipe.description.isEmpty

        populateTags()
        populateNutrition()
        populateIngredients()
        populateInstructions()

        saveButton.isHidden = saved
        updateServingsLabels()
        updateFavoriteButton()
    }

    private func populateTags() {
        let values = (recipe.tags ?? []).filter { !$0.isEmpty }
        tagsWrapView.isHidden = values.isEmpty
        tagsWrapView.setItems(values.map(makeTagPill))
    }

    private func makeTagPill(_ text: String) -> UIView {
        let label = UILabel()
        label.text = text
        label.font = WFUIFont.body(10.5, weight: .bold)
        label.textColor = WFUIPalette.selectedText
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        let pill = UIView()
        pill.backgroundColor = WFUIPalette.selectedBackground
        pill.layer.cornerRadius = 12
        pill.layer.cornerCurve = .continuous
        pill.clipsToBounds = true
        pill.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: pill.topAnchor, constant: 5),
            label.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -5),
            label.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -10)
        ])
        return pill
    }

    private func populateNutrition() {
        nutritionSection.arrangedSubviews.forEach { $0.removeFromSuperview() }

        guard let cal = recipe.cal else {
            nutritionSection.isHidden = true
            return
        }
        nutritionSection.isHidden = false

        nutritionSection.addArrangedSubview(WFUISectionTitleLabel("Nutrition"))

        let cards = UIStackView.wf(axis: .horizontal, spacing: 9, distribution: .fillEqually, views: [
            WFUINutritionCardView(
                label: "kcal",
                value: cal.totalCalories ?? "—",
                color: WFUIPalette.greenText,
                background: WFUIPalette.greenBackground
            ),
            WFUINutritionCardView(
                label: "carbs",
                value: cal.carbs,
                color: WFUIPalette.macroCarbsText,
                background: WFUIPalette.macroCarbsBackground
            ),
            WFUINutritionCardView(
                label: "protein",
                value: cal.protein,
                color: WFUIPalette.macroProteinText,
                background: WFUIPalette.macroProteinBackground
            ),
            WFUINutritionCardView(
                label: "fat",
                value: cal.fat,
                color: WFUIPalette.macroFatText,
                background: WFUIPalette.macroFatBackground
            )
        ])
        nutritionSection.addArrangedSubview(cards)
    }

    private func populateIngredients() {
        ingredientRowsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, ingredient) in recipe.ingredients.enumerated() {
            let divider = UIView()
            divider.backgroundColor = WFUIPalette.divider
            divider.translatesAutoresizingMaskIntoConstraints = false
            divider.heightAnchor.constraint(equalToConstant: 1).isActive = true

            let dividerWrapper = UIView()
            dividerWrapper.addSubview(divider)
            NSLayoutConstraint.activate([
                divider.topAnchor.constraint(equalTo: dividerWrapper.topAnchor),
                divider.bottomAnchor.constraint(equalTo: dividerWrapper.bottomAnchor),
                divider.leadingAnchor.constraint(equalTo: dividerWrapper.leadingAnchor, constant: 52),
                divider.trailingAnchor.constraint(equalTo: dividerWrapper.trailingAnchor)
            ])
            ingredientRowsStack.addArrangedSubview(dividerWrapper)

            let row = WFUIIngredientRowView(index: index) { [weak self] tappedIndex in
                self?.toggleIngredient(at: tappedIndex)
            }
            row.configure(
                text: WFIngredientScaler.scale(ingredient, from: baseServings, to: servings),
                checked: checkedIngredients.contains(ingredient)
            )
            ingredientRowsStack.addArrangedSubview(row)
        }
    }

    private func populateInstructions() {
        instructionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, step) in recipe.recipe.enumerated() {
            let isLast = index == recipe.recipe.count - 1
            instructionsStack.addArrangedSubview(
                WFUIInstructionStepView(number: index + 1, text: step, showsConnector: !isLast)
            )
        }
    }

    private func updateServingsLabels() {
        servingsCountLabel.text = "\(servings) serv."
        servingsValueLabel.setValue("\(servings)")
    }

    private func updateFavoriteButton() {
        let isFavorite = appState.isFavorite(recipe)
        favoriteButton.image = UIImage(systemName: isFavorite ? "heart.fill" : "heart")
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        close()
    }

    @objc private func toggleFavorite() {
        appState.toggleFavorite(recipe)
        // The button refreshes from the $favoriteRecipes subscription
    }

    @objc private func shareRecipe() {
        let activity = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        activity.popoverPresentationController?.barButtonItem = shareButton
        present(activity, animated: true)
    }

    @objc private func saveRecipe() {
        Task { @MainActor in
            if await appState.save(recipe) {
                saved = true
                saveButton.isHidden = true
            }
        }
    }

    @objc private func startCooking() {
        // Cooking mode is still the SwiftUI implementation, hosted here
        let cookingView = WFCookingModeView(steps: recipe.recipe)
        let host = UIHostingController(rootView: cookingView)
        host.modalPresentationStyle = .fullScreen
        present(host, animated: true)
    }

    @objc private func showRemix() {
        let sheet = UIAlertController(title: "Remix", message: "Pick a twist", preferredStyle: .actionSheet)
        for twist in ["Make it healthier", "Make it spicier", "Make it vegetarian", "Make it quicker"] {
            sheet.addAction(UIAlertAction(title: twist, style: .default) { [weak self] _ in
                self?.performRemix(twist)
            })
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        sheet.popoverPresentationController?.sourceView = view
        present(sheet, animated: true)
    }

    private func performRemix(_ twist: String) {
        let loading = UIAlertController(title: nil, message: "Remixing…", preferredStyle: .alert)
        present(loading, animated: true)

        Task { @MainActor in
            let result = await appState.remix(recipe, twist: twist)
            loading.dismiss(animated: true) { [weak self] in
                guard let self, let result else { return }
                self.recipe = result
                self.servings = Self.parseServings(result.servings)
                self.checkedIngredients = Self.loadCheckedIngredients(for: result)
                self.saved = false
                self.populate()
            }
        }
    }

    @objc private func decreaseServings() {
        servings = max(1, servings - 1)
        updateServingsLabels()
        populateIngredients()
    }

    @objc private func increaseServings() {
        servings = min(12, servings + 1)
        updateServingsLabels()
        populateIngredients()
    }

    private func toggleIngredient(at index: Int) {
        guard index < recipe.ingredients.count else { return }
        let ingredient = recipe.ingredients[index]

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if checkedIngredients.contains(ingredient) {
            checkedIngredients.remove(ingredient)
        } else {
            checkedIngredients.insert(ingredient)
        }

        Self.saveCheckedIngredients(checkedIngredients, for: recipe)
        populateIngredients()
    }

    // MARK: - Checked-ingredient persistence

    private static func checkedIngredientsKey(for recipe: RecipeResponseModel) -> String {
        "wf.checkedIngredients.\(recipe.wfIdentifier)"
    }

    private static func loadCheckedIngredients(for recipe: RecipeResponseModel) -> Set<String> {
        let stored = UserDefaults.standard.stringArray(forKey: checkedIngredientsKey(for: recipe)) ?? []
        // Drop anything no longer in the recipe (e.g. after a remix)
        return Set(stored).intersection(recipe.ingredients)
    }

    private static func saveCheckedIngredients(_ checked: Set<String>, for recipe: RecipeResponseModel) {
        let key = checkedIngredientsKey(for: recipe)
        if checked.isEmpty {
            UserDefaults.standard.removeObject(forKey: key)
        } else {
            UserDefaults.standard.set(Array(checked), forKey: key)
        }
    }

    // MARK: - Helpers

    private var shareText: String {
        let steps = recipe.recipe.enumerated()
            .map { "\($0.offset + 1). \($0.element)" }
            .joined(separator: "\n")
        return "\(recipe.foodName)\n\nIngredients\n\(recipe.ingredients.joined(separator: "\n"))\n\nInstructions\n\(steps)"
    }

    private static func parseServings(_ text: String?) -> Int {
        guard let text else { return 2 }
        // Take the FIRST number only. Joining all digit groups turned "4-6"
        // into "46", which then clamped to 12.
        let firstNumber = text
            .components(separatedBy: CharacterSet.decimalDigits.inverted)
            .first(where: { !$0.isEmpty })
        return min(12, max(1, firstNumber.flatMap(Int.init) ?? 2))
    }

    /// Point at which the hero has scrolled past the navigation bar.
    private var heroFadeDistance: CGFloat {
        max(heroHeight - view.safeAreaInsets.top - 44, 1)
    }

    private func updateNavigationBar(for offset: CGFloat) {
        let alpha = min(max(offset / heroFadeDistance, 0), 1)

        // The bar never gets a background — the title just fades in and the item
        // tint flips once the hero photo has scrolled out from under it.
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [
            .foregroundColor: WFUIPalette.text.withAlphaComponent(titleAlpha(for: alpha)),
            .font: WFUIFont.heading(16, weight: .bold)
        ]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = alpha > 0.5 ? WFUIPalette.text : .white

        navigationItem.title = recipe.foodName
        setNeedsStatusBarAppearanceUpdate()
    }

    /// Title stays hidden over the photo, then fades in over the last half of the scroll.
    private func titleAlpha(for alpha: CGFloat) -> CGFloat {
        min(max((alpha - 0.5) * 2, 0), 1)
    }
}

// MARK: - UIScrollViewDelegate

extension WFRecipeDetailViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateNavigationBar(for: scrollView.contentOffset.y)
    }
}

// MARK: - Subviews

/// One cell of the PREP / COOK / SERVES / LEVEL strip.
final class WFUIMetaItemView: UIView {
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = WFUIFont.heading(11.5, weight: .bold)
        label.textColor = WFUIPalette.text
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.72
        return label
    }()

    init(label: String, value: String) {
        super.init(frame: .zero)

        let titleLabel = UILabel()
        titleLabel.text = label
        titleLabel.font = WFUIFont.body(9.5, weight: .bold)
        titleLabel.textColor = WFUIPalette.secondaryText
        titleLabel.textAlignment = .center

        valueLabel.text = value

        let stack = UIStackView.wf(axis: .vertical, spacing: 5, views: [titleLabel, valueLabel])
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setValue(_ value: String) {
        valueLabel.text = value
    }
}

final class WFUIMetaDividerView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = WFUIPalette.divider
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 1),
            heightAnchor.constraint(equalToConstant: 31)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class WFUINutritionCardView: UIView {
    init(label: String, value: String, color: UIColor, background: UIColor) {
        super.init(frame: .zero)

        backgroundColor = background
        layer.cornerRadius = 14
        layer.cornerCurve = .continuous

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = WFUIFont.heading(14, weight: .bold)
        valueLabel.textColor = color
        valueLabel.textAlignment = .center
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.7

        let nameLabel = UILabel()
        nameLabel.text = label
        nameLabel.font = WFUIFont.body(10, weight: .semibold)
        nameLabel.textColor = color.withAlphaComponent(0.75)
        nameLabel.textAlignment = .center

        let stack = UIStackView.wf(axis: .vertical, spacing: 3, views: [valueLabel, nameLabel])
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Tappable ingredient line with a checkbox and strike-through when checked.
final class WFUIIngredientRowView: UIControl {
    private let index: Int
    private let onTap: (Int) -> Void

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

    private let label: UILabel = {
        let label = UILabel()
        label.font = WFUIFont.body(14, weight: .semibold)
        label.numberOfLines = 0
        return label
    }()

    init(index: Int, onTap: @escaping (Int) -> Void) {
        self.index = index
        self.onTap = onTap
        super.init(frame: .zero)

        checkbox.addSubview(checkmark)
        let stack = UIStackView.wf(axis: .horizontal, spacing: 12, alignment: .top, views: [checkbox, label])
        stack.isUserInteractionEnabled = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 13),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -13),

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

    func configure(text: String, checked: Bool) {
        checkbox.backgroundColor = checked ? WFUIPalette.orange : .clear
        checkbox.layer.borderColor = (checked ? UIColor.clear : WFUIPalette.border).cgColor
        checkmark.isHidden = !checked

        label.textColor = checked ? WFUIPalette.tertiaryText : WFUIPalette.text
        if checked {
            label.attributedText = NSAttributedString(
                string: text,
                attributes: [
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .strikethroughColor: WFUIPalette.tertiaryText
                ]
            )
        } else {
            label.attributedText = nil
            label.text = text
        }
    }

    @objc private func handleTap() {
        onTap(index)
    }
}

/// Numbered instruction step with a dashed connector down to the next one.
final class WFUIInstructionStepView: UIView {
    init(number: Int, text: String, showsConnector: Bool) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let numberLabel = UILabel()
        numberLabel.text = "\(number)"
        numberLabel.font = WFUIFont.heading(12, weight: .bold)
        numberLabel.textColor = .white
        numberLabel.textAlignment = .center
        numberLabel.backgroundColor = WFUIPalette.orange
        numberLabel.layer.cornerRadius = 14.5
        numberLabel.clipsToBounds = true
        numberLabel.translatesAutoresizingMaskIntoConstraints = false

        let stepLabel = UILabel()
        stepLabel.text = text
        stepLabel.font = WFUIFont.body(14.5)
        stepLabel.textColor = WFUIPalette.text
        stepLabel.numberOfLines = 0
        stepLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(numberLabel)
        addSubview(stepLabel)

        NSLayoutConstraint.activate([
            numberLabel.topAnchor.constraint(equalTo: topAnchor),
            numberLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            numberLabel.widthAnchor.constraint(equalToConstant: 29),
            numberLabel.heightAnchor.constraint(equalToConstant: 29),

            stepLabel.topAnchor.constraint(equalTo: topAnchor),
            stepLabel.leadingAnchor.constraint(equalTo: numberLabel.trailingAnchor, constant: 13),
            stepLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            stepLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        if showsConnector {
            let connector = WFUIStepConnectorView(frame: .zero)
            connector.translatesAutoresizingMaskIntoConstraints = false
            addSubview(connector)
            NSLayoutConstraint.activate([
                connector.topAnchor.constraint(equalTo: numberLabel.bottomAnchor, constant: 4),
                connector.centerXAnchor.constraint(equalTo: numberLabel.centerXAnchor),
                connector.widthAnchor.constraint(equalToConstant: 2),
                // Reaches into the stack's spacing so the dashes look continuous
                connector.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 16)
            ])
        } else {
            numberLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor).isActive = true
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
