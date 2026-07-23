import UIKit
import Kingfisher
import FirebaseFirestore

class ShowFoodVC: DataLoadingVC {
    var selectedFoods: [Ingredient] = []
    var selectedCategory: [String] = []
    private lazy var image = UIImage(named: "recipe_background")
    
    enum RecipeMode {
        case selected
        case random
        case detail
    }
    
    var mode: RecipeMode = .selected
    
    // MARK: - UI Components
    
    // Header Image View
    var imageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    // Cook Time Label
    private lazy var cookTimeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .right
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Recipe Name Label
    private lazy var foodNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 2
        label.font = .preferredFont(forTextStyle: .headline).withSize(18)
        return label
    }()
    
    // Tags Collection View
    private lazy var tagsView: TagsCollectionView = {
        let tagsView = TagsCollectionView()
        tagsView.translatesAutoresizingMaskIntoConstraints = false
        return tagsView
    }()
    
    // Nutrition Widget
    private lazy var nutritionWidget: NutritionWidget = {
        let widget = NutritionWidget()
        widget.translatesAutoresizingMaskIntoConstraints = false
        widget.layer.cornerRadius = 12
        widget.clipsToBounds = true
        widget.backgroundColor = .systemBackground
        return widget
    }()
    
    // Main Scroll View
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()
    
    // Content Container View
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Section Headers
    private lazy var ingredientsHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Ingredients", comment: "")
        label.font = .boldSystemFont(ofSize: 18)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var instructionsHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Instructions", comment: "")
        label.font = .boldSystemFont(ofSize: 18)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Ingredients List
    private lazy var ingredientsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // Instructions List
    private lazy var instructionsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // Save Button (now as navigation bar button)
    private lazy var saveNavButton: UIBarButtonItem = {
        return UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.down"),
            style: .plain,
            target: self,
            action: #selector(saveRecipe)
        )
    }()

    // Keep old save button for backward compatibility if needed
    private lazy var saveButton: UIButton = {
        let button = UIButton()
        button.setTitle(NSLocalizedString(LocaleKeys.DetailRecipe.saveButton.rawValue, comment: "Save Recipe"), for: .normal)
        button.backgroundColor = Colors.primary.color
        button.addTarget(self, action: #selector(saveRecipe), for: .touchUpInside)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true // Hide the old button
        return button
    }()
    
    private lazy var labelsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 2
        stackView.alignment = .trailing
        stackView.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private var ingredientsContainer: UIView!
    private var ingredientsHeaderView: UIView!
    private var saveButtonTopConstraint: NSLayoutConstraint?

    // MARK: - Servings scaling

    /// One ingredient line, split so the quantity can be rescaled independently of the text.
    private struct ParsedIngredient {
        let name: String
        let quantity: Double?
        let unit: String
        /// Original amount text, used when there is no number we can scale.
        let rawAmount: String
    }

    private var parsedIngredients: [ParsedIngredient] = []
    private var baseServings: Int = 1
    private var currentServings: Int = 1

    private lazy var servingsStepper: UIStepper = {
        let stepper = UIStepper()
        stepper.minimumValue = 1
        stepper.maximumValue = 20
        stepper.stepValue = 1
        stepper.translatesAutoresizingMaskIntoConstraints = false
        stepper.addTarget(self, action: #selector(servingsChanged), for: .valueChanged)
        return stepper
    }()

    private lazy var servingsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var servingsRow: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [servingsLabel, servingsStepper])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // Nav Bar Buttons
    private lazy var favButton: UIBarButtonItem = {
        return UIBarButtonItem(
            image: UIImage(systemName: "heart"),
            style: .plain,
            target: self,
            action: #selector(toggleFavorite)
        )
    }()

    // Gradient Layer (only for iOS < 26)
    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        let topColor = UIColor.clear.cgColor
        let bottomColor = UIColor.black.withAlphaComponent(0.8).cgColor
        layer.colors = [topColor, bottomColor]
        layer.locations = [0.0, 1.0]
        return layer
    }()


    // Activity Indicator
    private lazy var indicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.style = .large
        indicator.color = Colors.primary.color
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private lazy var refreshButton: UIBarButtonItem = {
        return UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(refreshButtonTapped)
        )
    }()
    
    private let viewModel = ShowFoodViewModel()
    var recipe: RecipeResponseModel?
    
    private var ingredientsContainerHeightConstraint: NSLayoutConstraint?
    private var instructionsSectionTopConstraint: NSLayoutConstraint?
    private var nutritionWidgetTopConstraint: NSLayoutConstraint?
    private var tagsViewTopConstraint: NSLayoutConstraint?
    private var tagsViewHeightConstraint: NSLayoutConstraint?
    private var ingredientsHeaderTopConstraint: NSLayoutConstraint?
    
    
    private var previousScrollOffset: CGFloat = 0
    private var isTitleVisible = false
    private var navBarTransitionPoint: CGFloat {
        // The image is as tall as the screen is wide; the bar becomes opaque
        // right as the bottom of the image reaches the bottom of the nav bar.
        let imageHeight = UIScreen.main.bounds.width
        let barBottom = view.safeAreaInsets.top + (navigationController?.navigationBar.frame.height ?? 44)

        return max(imageHeight - barBottom, 1)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return isTitleVisible ? .default : .lightContent
    }
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
        
        setupUI()
        viewModel.delegate = self
        
        switch mode {
        case .selected:
            viewModel.fetchFoodRecipe(foods: selectedFoods, category: selectedCategory)
        case .random:
            viewModel.fetchRandomRecipe()
        case .detail:
            if let recipe = recipe {
                viewModel.load(recipe: recipe)
                updateUI(with: recipe)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if mode == .random || mode == .detail {
            tabBarController?.tabBar.isHidden = true
        }
        
        // Start out over the photo: white items on a transparent bar
        updateNavBarAppearance(scrollOffset: scrollView.contentOffset.y)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        imageView.kf.cancelDownloadTask()
        indicator.stopAnimating()
        NotificationCenter.default.removeObserver(self)
        tabBarController?.tabBar.isHidden = false

        // Hand the navigation bar back in its default state
        let defaultAppearance = UINavigationBarAppearance()
        defaultAppearance.configureWithDefaultBackground()
        navigationController?.navigationBar.standardAppearance = defaultAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = nil
        navigationController?.navigationBar.tintColor = Colors.accent.color
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Only update gradient for iOS < 26, since iOS 26+ uses glass effect
        if #unavailable(iOS 26.0) {
            gradientLayer.frame = imageView.bounds
        }

        updateDashLinesAfterLayout()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        setupNavigationBar()
        setupScrollView()
        setupImageView()
        setupLabels()
        setupTagsView()
        setupNutritionWidget()
        setupIngredientsSection()
        createInstructionStep()
        setupSaveButton()
        setupIndicator()
        setupScrollViewDelegate()
        
        if mode == .detail {
            setupFavButton()
            configureFavButton()
            saveButton.isHidden = true
        } else {
            setupSaveNavButton()
        }
        
        nutritionWidget.isHidden = true
        tagsView.isHidden = true
        
        if RateAppController.shared.shouldShowRateApp() {
            RateAppController.shared.showRateApp()
        }
    }
    
    private func setupScrollViewDelegate() {
        scrollView.delegate = self

        // Standard bar title; it stays invisible over the photo because the
        // transparent appearance uses a clear title color.
        navigationItem.titleView = nil
        navigationItem.title = recipe?.foodName
    }

    private func updateNavBarAppearance(scrollOffset: CGFloat) {
        let transitionDistance: CGFloat = 100
        let startTransition = navBarTransitionPoint - transitionDistance
        let alpha: CGFloat
        
        if scrollOffset <= startTransition {
            alpha = 0
        } else if scrollOffset >= navBarTransitionPoint {
            alpha = 1
        } else {
            alpha = (scrollOffset - startTransition) / transitionDistance
        }
        
        // Standard UIKit bar: transparent over the photo, default blurred material once scrolled
        let appearance = UINavigationBarAppearance()
        if alpha < 0.1 {
            appearance.configureWithTransparentBackground()
        } else {
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(alpha)
        }
        // Title only becomes visible as the bar becomes opaque
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label.withAlphaComponent(max(0, (alpha - 0.5) * 2))
        ]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance

        // Tint items so they stay legible over the photo
        navigationController?.navigationBar.tintColor = alpha > 0.5 ? Colors.accent.color : .white

        isTitleVisible = alpha > 0.5
        setNeedsStatusBarAppearanceUpdate()
    }
    
    private func setupNavigationBar() {
        navigationController?.navigationBar.isTranslucent = true

        // Native back button ("< Back") supplied by the navigation controller
        navigationItem.leftBarButtonItem = nil

        if mode == .detail {
            navigationItem.rightBarButtonItem = favButton
        } else {
            setupRefreshButton()
        }
        
        enableSwipeBackGesture()
    }
    
    private func setupScrollView() {
        // Let the content run under the status bar / notch instead of starting at the safe area
        scrollView.contentInsetAdjustmentBehavior = .never

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupImageView() {
        let size = UIScreen.main.bounds.width
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let sizePhoto = CGSize(width:size, height: size)
        let resizableImage = image!.resize(toSize: sizePhoto)
        imageView.image = resizableImage
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: size)
        ])

        // Only add gradient layer for iOS < 26, since iOS 26+ uses glass effect
        if #unavailable(iOS 26.0) {
            imageView.layer.addSublayer(gradientLayer)
        }
    }
    
    private func setupLabels() {
        contentView.addSubview(labelsStackView)
        labelsStackView.addArrangedSubview(foodNameLabel)
        labelsStackView.addArrangedSubview(cookTimeLabel)

        // Update label styling for below image placement
        foodNameLabel.textColor = .label
        foodNameLabel.textAlignment = .right
        cookTimeLabel.textColor = .secondaryLabel
        cookTimeLabel.textAlignment = .right
        labelsStackView.alignment = .trailing
        labelsStackView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 8, right: 16)

        NSLayoutConstraint.activate([
            labelsStackView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 0),
            labelsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            labelsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    
    private func setupTagsView() {
        contentView.addSubview(tagsView)
        
        tagsViewTopConstraint = tagsView.topAnchor.constraint(equalTo: labelsStackView.bottomAnchor, constant: 16)
        // Important: We don't set a fixed height constraint here
        // Let the TagsCollectionView determine its own height
        
        NSLayoutConstraint.activate([
            tagsViewTopConstraint!,
            tagsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            tagsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
        
        // Hide by default, will show if there are tags
        tagsView.isHidden = true
    }
    
    private func setupNutritionWidget() {
        contentView.addSubview(nutritionWidget)
        
        // Create the constraint but don't activate it yet - we'll manage it based on tags visibility
        nutritionWidgetTopConstraint = nutritionWidget.topAnchor.constraint(equalTo: tagsView.bottomAnchor, constant: 16)
        
        NSLayoutConstraint.activate([
            nutritionWidgetTopConstraint!,
            nutritionWidget.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nutritionWidget.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
        nutritionWidget.isHidden = true
    }
    
    private func setupIngredientsSection() {
        // Section header
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        let ingredientsLabel = UILabel()
        ingredientsLabel.text = "Ingredients".locale()
        ingredientsLabel.font = .systemFont(ofSize: 32, weight: .bold)
        ingredientsLabel.textColor = .label
        ingredientsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let toggleButton = UIButton()
        toggleButton.setImage(UIImage(systemName: "chevron.up"), for: .normal)
        toggleButton.tintColor = .label
        toggleButton.backgroundColor = .systemGray6
        toggleButton.layer.cornerRadius = 20
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        toggleButton.addTarget(self, action: #selector(toggleIngredientsVisibility), for: .touchUpInside)
        
        headerView.addSubview(ingredientsLabel)
        headerView.addSubview(toggleButton)
        
        // Container view with standard design
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = true
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4
        containerView.layer.shadowOpacity = 0.1
        
        // Create a wrapper to allow shadow and clipping
        let shadowWrapper = UIView()
        shadowWrapper.translatesAutoresizingMaskIntoConstraints = false
        shadowWrapper.layer.shadowColor = UIColor.black.cgColor
        shadowWrapper.layer.shadowOffset = CGSize(width: 0, height: 2)
        shadowWrapper.layer.shadowRadius = 4
        shadowWrapper.layer.shadowOpacity = 0.1
        
        // Standard ingredients stack view
        ingredientsStackView.axis = .vertical
        ingredientsStackView.spacing = 8
        ingredientsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(ingredientsStackView)
        shadowWrapper.addSubview(containerView)
        
        contentView.addSubview(headerView)
        contentView.addSubview(servingsRow)
        contentView.addSubview(shadowWrapper)

        containerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            servingsRow.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 12),
            servingsRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            servingsRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Header view constraints
            headerView.topAnchor.constraint(equalTo: nutritionWidget.bottomAnchor, constant: 30),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            ingredientsLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            ingredientsLabel.topAnchor.constraint(equalTo: headerView.topAnchor),
            ingredientsLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            
            toggleButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            toggleButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            toggleButton.widthAnchor.constraint(equalToConstant: 40),
            toggleButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Shadow wrapper constraints
            shadowWrapper.topAnchor.constraint(equalTo: servingsRow.bottomAnchor, constant: 10),
            shadowWrapper.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            shadowWrapper.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Container view constraints
            containerView.topAnchor.constraint(equalTo: shadowWrapper.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: shadowWrapper.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: shadowWrapper.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: shadowWrapper.bottomAnchor),
            
            // Ingredients stack view constraints
            ingredientsStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            ingredientsStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0),
            ingredientsStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -0),
            ingredientsStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
        
        // Store height constraint for collapsing
        ingredientsContainerHeightConstraint = shadowWrapper.heightAnchor.constraint(equalToConstant: 0)
        ingredientsContainerHeightConstraint?.isActive = false
        
        self.ingredientsContainer = shadowWrapper
        self.ingredientsHeaderView = headerView
    }

    private func createIngredientRow(name: String, amount: String) -> UIView {
        let rowView = UIView()
        rowView.translatesAutoresizingMaskIntoConstraints = false
        
        // Checkbox with modern style
        let checkboxView = UIView()
        checkboxView.translatesAutoresizingMaskIntoConstraints = false
        checkboxView.layer.borderWidth = 1
        checkboxView.layer.borderColor = Colors.primary.color.cgColor
        checkboxView.layer.cornerRadius = 10
        checkboxView.backgroundColor = UIColor.clear
        checkboxView.tag = 1001 // Tag for identifying and tracking state
        
        // Name label with system font
        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = .systemFont(ofSize: 16)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.adjustsFontSizeToFitWidth = true
        
        // Amount label
        let amountLabel = UILabel()
        amountLabel.text = amount
        amountLabel.font = .systemFont(ofSize: 16, weight: .medium)
        amountLabel.textColor = .secondaryLabel
        amountLabel.textAlignment = .right
        amountLabel.tag = 1004 // Looked up when servings change
        amountLabel.translatesAutoresizingMaskIntoConstraints = false

        // Standard separator
        let separatorView = UIView()
        separatorView.backgroundColor = .separator
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        
        rowView.addSubview(checkboxView)
        rowView.addSubview(nameLabel)
        rowView.addSubview(amountLabel)
        rowView.addSubview(separatorView)
        
        NSLayoutConstraint.activate([
            checkboxView.leadingAnchor.constraint(equalTo: rowView.leadingAnchor, constant: 0),
            checkboxView.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            checkboxView.widthAnchor.constraint(equalToConstant: 20),
            checkboxView.heightAnchor.constraint(equalToConstant: 20),
            
            nameLabel.leadingAnchor.constraint(equalTo: checkboxView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: rowView.topAnchor, constant: 12),
            nameLabel.bottomAnchor.constraint(equalTo: rowView.bottomAnchor, constant: -12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: amountLabel.leadingAnchor, constant: -8),
            
            amountLabel.trailingAnchor.constraint(equalTo: rowView.trailingAnchor, constant: -12),
            amountLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            amountLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 120),
            
            separatorView.leadingAnchor.constraint(equalTo: rowView.leadingAnchor, constant: 8),
            separatorView.trailingAnchor.constraint(equalTo: rowView.trailingAnchor, constant: -8),
            separatorView.bottomAnchor.constraint(equalTo: rowView.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5)
        ])
        
        // Add tap gesture to toggle checkbox
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleCheckbox(_:)))
        rowView.addGestureRecognizer(tapGesture)
        rowView.isUserInteractionEnabled = true
        
        return rowView
    }

    @objc private func toggleCheckbox(_ sender: UITapGestureRecognizer) {
        guard let rowView = sender.view else { return }
        guard let checkboxView = rowView.viewWithTag(1001) else { return }
        
        // Get the name label safely
        let nameLabels = rowView.subviews.filter { $0 is UILabel && $0 != rowView.subviews.last }
        guard let nameLabel = nameLabels.first as? UILabel else { return }
        
        // Check if checkbox is already checked (using a tag instead of sublayers)
        let isChecked = checkboxView.tag == 1002
        
        if !isChecked {
            // Add checkmark as a UIImageView instead of layer
            let checkmarkImage = UIImageView(image: UIImage(systemName: "checkmark"))
            checkmarkImage.tintColor = Colors.primary.color
            checkmarkImage.translatesAutoresizingMaskIntoConstraints = false
            checkmarkImage.tag = 1003 // Tag for the checkmark
            
            checkboxView.backgroundColor = Colors.primary.color.withAlphaComponent(0.1)
            checkboxView.addSubview(checkmarkImage)
            
            NSLayoutConstraint.activate([
                checkmarkImage.centerXAnchor.constraint(equalTo: checkboxView.centerXAnchor),
                checkmarkImage.centerYAnchor.constraint(equalTo: checkboxView.centerYAnchor),
                checkmarkImage.widthAnchor.constraint(equalTo: checkboxView.widthAnchor, multiplier: 0.8),
                checkmarkImage.heightAnchor.constraint(equalTo: checkboxView.heightAnchor, multiplier: 0.8)
            ])
            
            // Mark as checked using tag
            checkboxView.tag = 1002
            
            // Strike through text
            let attributeString = NSMutableAttributedString(string: nameLabel.text ?? "")
            attributeString.addAttribute(.strikethroughStyle, value: 1, range: NSRange(location: 0, length: attributeString.length))
            nameLabel.attributedText = attributeString
            nameLabel.alpha = 0.5
        } else {
            // Remove checkmark
            checkboxView.subviews.forEach {
                if $0.tag == 1003 {
                    $0.removeFromSuperview()
                }
            }
            
            // Reset background
            checkboxView.backgroundColor = .clear
            
            // Mark as unchecked
            checkboxView.tag = 1001
            
            // Remove strike through
            nameLabel.attributedText = nil
            nameLabel.text = nameLabel.text
            nameLabel.alpha = 1.0
        }
    }
    
    private func setupInstructionsSection() {
        // Bölüm başlığı
        let directionsLabel = UILabel()
        directionsLabel.text = "Instructions".locale()
        directionsLabel.font = .systemFont(ofSize: 32, weight: .bold)
        directionsLabel.textColor = .label
        directionsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Talimatları tutacak stack view
        instructionsStackView.axis = .vertical
        instructionsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(directionsLabel)
        contentView.addSubview(instructionsStackView)
        
        // Create constraint that we can modify
        instructionsSectionTopConstraint = directionsLabel.topAnchor.constraint(equalTo: ingredientsContainer.bottomAnchor, constant: 30)

        NSLayoutConstraint.activate([
            instructionsSectionTopConstraint!,
            directionsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            directionsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            instructionsStackView.topAnchor.constraint(equalTo: directionsLabel.bottomAnchor, constant: 20),
            instructionsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            instructionsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }
    
    private func createInstructionStep() {
        // Bölüm başlığı
        let directionsLabel = UILabel()
        directionsLabel.text = "Instructions".locale()
        directionsLabel.font = .systemFont(ofSize: 32, weight: .bold)
        directionsLabel.textColor = .label
        directionsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Talimatları tutacak stack view
        instructionsStackView.axis = .vertical
        instructionsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(directionsLabel)
        contentView.addSubview(instructionsStackView)
        
        // Store this constraint to update when toggling ingredients
        instructionsSectionTopConstraint = directionsLabel.topAnchor.constraint(equalTo: ingredientsContainer.bottomAnchor, constant: 30)
        
        NSLayoutConstraint.activate([
            instructionsSectionTopConstraint!,
            directionsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            directionsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            instructionsStackView.topAnchor.constraint(equalTo: directionsLabel.bottomAnchor, constant: 20),
            instructionsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            instructionsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }
    
    private func createInstructionStep(number: Int, instruction: String) -> UIView {
        let spacing: CGFloat = 4
        let stepView = UIView()
        stepView.translatesAutoresizingMaskIntoConstraints = false
        
        // Adım numarası için daire
        let numberCircle = UIView()
        numberCircle.backgroundColor = Colors.primary.color
        numberCircle.layer.cornerRadius = 12
        numberCircle.translatesAutoresizingMaskIntoConstraints = false
        
        let numberLabel = UILabel()
        numberLabel.text = "\(number)"
        numberLabel.font = .preferredFont(forTextStyle: .headline).withSize(12)
        numberLabel.textColor = .white
        numberLabel.textAlignment = .center
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Talimat metni
        let instructionLabel = UILabel()
        instructionLabel.text = instruction
        instructionLabel.font = .systemFont(ofSize: 18)
        instructionLabel.textColor = .label
        instructionLabel.numberOfLines = 0
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Separator çizgi
        let separatorView = UIView()
        separatorView.backgroundColor = .systemGray4
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create a container for the dash line
        let dashLineContainer = UIView()
        dashLineContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Dash line layer for connecting steps will be added after layout
        
        numberCircle.addSubview(numberLabel)
        stepView.addSubview(dashLineContainer)
        stepView.addSubview(numberCircle)
        stepView.addSubview(instructionLabel)
        stepView.addSubview(separatorView)
        
        // Store constraints array to activate later
        var constraints = [
            numberCircle.leadingAnchor.constraint(equalTo: stepView.leadingAnchor, constant: spacing),
            numberCircle.topAnchor.constraint(equalTo: stepView.topAnchor, constant: spacing),
            numberCircle.widthAnchor.constraint(equalToConstant: 25),
            numberCircle.heightAnchor.constraint(equalToConstant: 25),
            
            numberLabel.centerXAnchor.constraint(equalTo: numberCircle.centerXAnchor),
            numberLabel.centerYAnchor.constraint(equalTo: numberCircle.centerYAnchor),
            
            instructionLabel.leadingAnchor.constraint(equalTo: numberCircle.trailingAnchor, constant: 16),
            instructionLabel.trailingAnchor.constraint(equalTo: stepView.trailingAnchor),
            instructionLabel.topAnchor.constraint(equalTo: stepView.topAnchor, constant: spacing),
            instructionLabel.bottomAnchor.constraint(equalTo: stepView.bottomAnchor, constant: -16),
            
            separatorView.leadingAnchor.constraint(equalTo: instructionLabel.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: stepView.trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: stepView.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1),
            
            dashLineContainer.centerXAnchor.constraint(equalTo: numberCircle.centerXAnchor),
            dashLineContainer.widthAnchor.constraint(equalToConstant: 2),
            // Runs from just under this step's number down to the next one
            dashLineContainer.topAnchor.constraint(equalTo: numberCircle.bottomAnchor, constant: spacing),
            dashLineContainer.bottomAnchor.constraint(equalTo: stepView.bottomAnchor)
        ]

        dashLineContainer.tag = 2001 // Looked up when drawing the dashes

        NSLayoutConstraint.activate(constraints)
        
        // Add a method to the view for updating the dash line
        stepView.layer.name = "step-\(number)"
        
        // Return the view - we'll add the dash line layer after layout
        return stepView
    }

    private func updateDashLinesAfterLayout() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            for (index, stepView) in self.instructionsStackView.arrangedSubviews.enumerated() {
                // Get the dash line container
                guard let dashLineContainer = stepView.viewWithTag(2001) else { continue }
                
                // Clear any existing dash lines
                dashLineContainer.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
                
                // If this is the last step, hide the dash line
                if index == self.instructionsStackView.arrangedSubviews.count - 1 {
                    dashLineContainer.isHidden = true
                    continue
                }
                
                // Show the dash line for all other steps
                dashLineContainer.isHidden = false
                
                // Create the dash line layer
                let dashLineLayer = CAShapeLayer()
                dashLineLayer.strokeColor = Colors.primary.color.withAlphaComponent(0.5).cgColor
                dashLineLayer.lineWidth = 2
                dashLineLayer.lineDashPattern = [4, 4]
                
                // Create the path for the dash line
                let path = UIBezierPath()
                path.move(to: CGPoint(x: dashLineContainer.bounds.width / 2, y: 0))
                path.addLine(to: CGPoint(x: dashLineContainer.bounds.width / 2, y: dashLineContainer.bounds.height))
                dashLineLayer.path = path.cgPath
                
                // Add the dash line layer to the container
                dashLineContainer.layer.addSublayer(dashLineLayer)
            }
        }
    }
    
    private func addChefsTip(tip: String) {
        let tipView = UIView()
        tipView.translatesAutoresizingMaskIntoConstraints = false
        
        let containerView = UIView()
        containerView.backgroundColor = UIColor(red: 1.0, green: 0.98, blue: 0.9, alpha: 1.0) // Açık sarı
        containerView.layer.cornerRadius = 12
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let sparkleImage = UIImageView(image: UIImage(systemName: "sparkles"))
        sparkleImage.tintColor = .orange
        sparkleImage.contentMode = .scaleAspectFit
        sparkleImage.translatesAutoresizingMaskIntoConstraints = false
        
        let tipTitleLabel = UILabel()
        tipTitleLabel.text = "chefs_tip".locale()
        tipTitleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        tipTitleLabel.textColor = .black
        tipTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let titleStack = UIStackView(arrangedSubviews: [sparkleImage, tipTitleLabel])
        titleStack.axis = .horizontal
        titleStack.spacing = 6
        titleStack.alignment = .center
        titleStack.translatesAutoresizingMaskIntoConstraints = false
        
        let tipLabel = UILabel()
        tipLabel.text = tip
        tipLabel.font = .systemFont(ofSize: 16)
        tipLabel.textColor = .black
        tipLabel.numberOfLines = 0
        tipLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(titleStack)
        containerView.addSubview(tipLabel)
        tipView.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            // Sparkle ikon için kısıtlamalar
            sparkleImage.widthAnchor.constraint(equalToConstant: 20),
            sparkleImage.heightAnchor.constraint(equalToConstant: 20),
            
            // Title stack için kısıtlamalar
            titleStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            
            // Tip etiketi için kısıtlamalar
            tipLabel.topAnchor.constraint(equalTo: titleStack.bottomAnchor, constant: 8),
            tipLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            tipLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            tipLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            
            // Container görünümü için kısıtlamalar
            containerView.topAnchor.constraint(equalTo: tipView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: tipView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: tipView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: tipView.bottomAnchor)
        ])
        
        contentView.addSubview(tipView)
        
        NSLayoutConstraint.activate([
            tipView.topAnchor.constraint(equalTo: instructionsStackView.bottomAnchor, constant: 24),
            tipView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tipView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        
        // Save butonunun kısıtlamasını güncelle
        if let saveButtonTopConstraint = saveButtonTopConstraint {
            saveButtonTopConstraint.isActive = false
        }
        
        saveButtonTopConstraint = saveButton.topAnchor.constraint(equalTo: tipView.bottomAnchor, constant: 32)
        saveButtonTopConstraint?.isActive = true
    }
    
    private func setupSaveButton() {
        contentView.addSubview(saveButton)
        
        NSLayoutConstraint.activate([
            saveButton.topAnchor.constraint(equalTo: instructionsStackView.bottomAnchor, constant: 32),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: view.bounds.height * 0.07),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupIndicator() {
        view.addSubview(indicator)
        
        NSLayoutConstraint.activate([
            indicator.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            indicator.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
        ])
    }
    
    private func setupRefreshButton() {
        navigationItem.rightBarButtonItem = refreshButton
    }
    
    private func setupFavButton() {
        navigationItem.rightBarButtonItem = favButton
    }

    private func setupSaveNavButton() {
        // For modes other than detail, show both refresh and save buttons
        setupRefreshButton()
        navigationItem.rightBarButtonItems = [saveNavButton, refreshButton]
    }
    
    private func enableSwipeBackGesture() {
        if let navigationController = self.navigationController {
            navigationController.interactivePopGestureRecognizer?.isEnabled = true
            navigationController.interactivePopGestureRecognizer?.delegate = nil
        }
    }
    
    // MARK: - UI Update Methods
    
    private func updateUI(with recipe: RecipeResponseModel) {
        foodNameLabel.text = recipe.foodName
        navigationItem.title = recipe.foodName
        
        if let time = recipe.totalTime {
            cookTimeLabel.text = recipe.totalTime
        } else {
            cookTimeLabel.text = recipe.cookTime
        }
        
        ingredientsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        instructionsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Add ingredients, keeping the parsed quantities so they can be rescaled
        baseServings = Self.parseServings(recipe.servings)
        currentServings = baseServings
        servingsStepper.value = Double(currentServings)
        updateServingsLabel()

        parsedIngredients = recipe.ingredients.map { Self.parseIngredient($0) }

        for parsed in parsedIngredients {
            let ingredientRow = createIngredientRow(name: parsed.name, amount: scaledAmountText(for: parsed))
            ingredientsStackView.addArrangedSubview(ingredientRow)
        }

        if let lastRow = ingredientsStackView.arrangedSubviews.last as? UIView,
           let separatorView = lastRow.subviews.last {
            separatorView.isHidden = true
        }

        // Add instructions
        for (index, instruction) in recipe.recipe.enumerated() {
            let stepView = createInstructionStep(number: index + 1, instruction: instruction)
            instructionsStackView.addArrangedSubview(stepView)
        }
        
        // Hide last separator
        if let lastStepView = instructionsStackView.arrangedSubviews.last as? UIView,
           let separatorView = lastStepView.subviews.last {
            separatorView.isHidden = true
        }
        
        DispatchQueue.main.async {
            self.updateDashLinesAfterLayout()
        }
        
        // Add chef tip if available
        if let tip = recipe.tips?.first {
            addChefsTip(tip: tip)
        }
        
        updateTagsVisibility(recipe: recipe)
        updateNutritionWidgetVisibility(recipe: recipe)
    }
    
    private func updateNutritionWidgetVisibility(recipe: RecipeResponseModel) {
        // Check if we have nutrition data
        let hasNutritionData = (recipe.cal != nil)
        
        nutritionWidget.isHidden = !hasNutritionData
        
        if hasNutritionData {
            // If we have nutrition data, update it
            if let nutritionInfo = recipe.cal {
                nutritionWidget.configure(with: nutritionInfo)
            }
        }
        
        // Update the ingredients header position based on what's visible
        if ingredientsHeaderTopConstraint == nil {
            ingredientsHeaderTopConstraint = ingredientsHeaderView.topAnchor.constraint(equalTo: nutritionWidget.bottomAnchor, constant: 30)
        }
        
        ingredientsHeaderTopConstraint?.isActive = false
        
        if !nutritionWidget.isHidden {
            ingredientsHeaderTopConstraint = ingredientsHeaderView.topAnchor.constraint(equalTo: nutritionWidget.bottomAnchor, constant: 30)
        } else if !tagsView.isHidden {
            ingredientsHeaderTopConstraint = ingredientsHeaderView.topAnchor.constraint(equalTo: tagsView.bottomAnchor, constant: 30)
        } else {
            // If both are hidden, position ingredients below image
            ingredientsHeaderTopConstraint = ingredientsHeaderView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 30)
        }
        
        ingredientsHeaderTopConstraint?.isActive = true
        
        // Force layout update
        contentView.layoutIfNeeded()
    }
    
    private func updateTagsVisibility(recipe: RecipeResponseModel) {
        // Check if we have tags
        let hasTags = (recipe.tags != nil && !recipe.tags!.isEmpty)
        
        if hasTags {
            tagsView.isHidden = false
            tagsView.configure(with: recipe.tags ?? [])
            
            // Make sure nutrition widget is positioned below tags
            nutritionWidgetTopConstraint?.isActive = false
            nutritionWidgetTopConstraint = nutritionWidget.topAnchor.constraint(equalTo: tagsView.bottomAnchor, constant: 16)
            nutritionWidgetTopConstraint?.isActive = true
        } else {
            tagsView.isHidden = true
            
            // If no tags, position nutrition widget directly below image
            nutritionWidgetTopConstraint?.isActive = false
            nutritionWidgetTopConstraint = nutritionWidget.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16)
            nutritionWidgetTopConstraint?.isActive = true
        }
        
        // Force layout update
        contentView.layoutIfNeeded()
    }
    
    // MARK: - Servings

    /// Pulls the first integer out of strings like "4 servings" / "4 kişilik".
    private static func parseServings(_ servings: String?) -> Int {
        guard let servings else { return 1 }
        let digits = servings.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }
        guard let first = digits.first, let value = Int(first), value > 0 else { return 1 }
        return value
    }

    /// Splits "• Tomato 2 adet" into a name and a scalable quantity.
    private static func parseIngredient(_ ingredient: String) -> ParsedIngredient {
        var name = ingredient
        var amount = ""

        let regex = try! NSRegularExpression(pattern: "([0-9]+[\\s]*[a-zA-Z]*$|\\d+\\/\\d+\\s*[a-zA-Z]*$)")
        if let match = regex.firstMatch(in: ingredient, range: NSRange(ingredient.startIndex..., in: ingredient)),
           let range = Range(match.range, in: ingredient) {
            amount = String(ingredient[range])
            name = ingredient.replacingOccurrences(of: amount, with: "").trimmingCharacters(in: .whitespaces)
        }

        // • işaretini de kaldır
        if name.hasPrefix("•") {
            name = name.replacingOccurrences(of: "•", with: "").trimmingCharacters(in: .whitespaces)
        }

        let (quantity, unit) = splitQuantity(from: amount)
        return ParsedIngredient(name: name, quantity: quantity, unit: unit, rawAmount: amount)
    }

    /// Separates the leading number (including "1/2" style fractions) from its unit.
    private static func splitQuantity(from amount: String) -> (Double?, String) {
        let trimmed = amount.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return (nil, "") }

        let pattern = "^(\\d+\\s*/\\s*\\d+|\\d+(?:[.,]\\d+)?)\\s*(.*)$"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
              let numberRange = Range(match.range(at: 1), in: trimmed),
              let unitRange = Range(match.range(at: 2), in: trimmed) else {
            return (nil, trimmed)
        }

        let numberText = String(trimmed[numberRange])
        let unit = String(trimmed[unitRange]).trimmingCharacters(in: .whitespaces)

        let value: Double?
        if numberText.contains("/") {
            let parts = numberText.components(separatedBy: "/").map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count == 2, let numerator = Double(parts[0]), let denominator = Double(parts[1]), denominator != 0 {
                value = numerator / denominator
            } else {
                value = nil
            }
        } else {
            value = Double(numberText.replacingOccurrences(of: ",", with: "."))
        }

        return (value, unit)
    }

    private func scaledAmountText(for ingredient: ParsedIngredient) -> String {
        guard let quantity = ingredient.quantity, baseServings > 0 else {
            // Nothing numeric to scale — leave the original text alone
            return ingredient.rawAmount
        }

        let scaled = quantity * Double(currentServings) / Double(baseServings)
        let formatted: String
        if scaled.rounded() == scaled {
            formatted = String(Int(scaled))
        } else {
            formatted = String(format: "%.2f", scaled)
                .replacingOccurrences(of: "0$", with: "", options: .regularExpression)
                .replacingOccurrences(of: "\\.$", with: "", options: .regularExpression)
        }

        return ingredient.unit.isEmpty ? formatted : "\(formatted) \(ingredient.unit)"
    }

    private func updateServingsLabel() {
        servingsLabel.text = "\(currentServings) " + "servings".locale()
    }

    @objc private func servingsChanged() {
        currentServings = Int(servingsStepper.value)
        updateServingsLabel()

        for (index, rowView) in ingredientsStackView.arrangedSubviews.enumerated() {
            guard index < parsedIngredients.count,
                  let amountLabel = rowView.viewWithTag(1004) as? UILabel else { continue }
            amountLabel.text = scaledAmountText(for: parsedIngredients[index])
        }
    }

    @objc private func toggleIngredientsVisibility() {
        guard let toggleButton = ingredientsHeaderView.subviews.last as? UIButton else { return }
        
        // Animating the collapse/expand
        UIView.animate(withDuration: 0.3) {
            if self.ingredientsContainer.isHidden {
                // Show ingredients
                self.ingredientsContainer.isHidden = false
                self.ingredientsContainerHeightConstraint?.isActive = false
                self.servingsRow.isHidden = false
                toggleButton.setImage(UIImage(systemName: "chevron.up"), for: .normal)
                
                // Adjust instruction section spacing
                self.instructionsSectionTopConstraint?.constant = 30
            } else {
                // Hide ingredients
                self.ingredientsContainerHeightConstraint?.isActive = true
                self.ingredientsContainerHeightConstraint?.constant = 0
                self.ingredientsContainer.isHidden = true
                self.servingsRow.isHidden = true
                toggleButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
                
                // Adjust instruction section spacing to be closer
                self.instructionsSectionTopConstraint?.constant = 10
            }
            
            // Force layout update
            self.contentView.layoutIfNeeded()
        }
    }
    
    // MARK: - Action Methods
    
    @objc func saveRecipe() {
        Task {
            guard let recipe else { return }
            await viewModel.saveRecipe(recipe)
        }
    }
    
    @objc func refreshButtonTapped() {
        switch mode {
        case .selected:
            viewModel.fetchFoodRecipe(foods: selectedFoods, category: selectedCategory)
        case .random:
            viewModel.fetchRandomRecipe()
        case .detail:
            break
        }
    }
    
    @objc func goBack() {
        if let viewControllers = navigationController?.viewControllers {
            for vc in viewControllers {
                if vc is HomeViewController {
                    navigationController?.popToViewController(vc, animated: true)
                    return
                }
            }
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    @objc func toggleFavorite() {
        guard let recipeResponse = self.recipe else { return }
        PersistenceManager.isSaved(recipe: recipeResponse) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let isSaved):
                if isSaved {
                    self.removeFav()
                } else {
                    self.addFav()
                }
            case .failure(_):
                break
            }
        }
    }
    
    @objc func addFav() {
        guard let recipe = self.recipe else { return }
        PersistenceManager.updateWith(favorite: recipe, actionType: .add) { _ in }
        configureFavButton()
    }
    
    @objc func removeFav() {
        guard let recipe = self.recipe else { return }
        PersistenceManager.updateWith(favorite: recipe, actionType: .remove) { _ in }
        configureFavButton()
    }
    
    func configureFavButton() {
        guard let recipeResponse = self.recipe else { return }
        PersistenceManager.isSaved(recipe: recipeResponse) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    // Favori durumuna göre uygun ikonu seçelim
                    if let customView = self.favButton.customView as? UIButton {
                        let heartImage = success ? UIImage(systemName: "heart.fill") : UIImage(systemName: "heart")
                        customView.setImage(heartImage, for: .normal)
                        customView.tintColor = .white
                    }
                case .failure(_):
                    break
                }
            }
        }
    }
}

// MARK: - ShowFoodViewDelegate
extension ShowFoodVC: ShowFoodViewDelegate {
    func handleViewModelOutput(_ output: ShowFoodViewModelOutput) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch output {
            case .setLoading(let isLoading):
                DispatchQueue.main.async {
                    if isLoading {
                        self.detailCustomLoadingView()
                    } else {
                        self.dismissLoadingView()
                    }
                }
                
            case .showRecipe(let recipe):
                self.recipe = recipe
                self.updateUI(with: recipe)
                
            case .showError(let error):
                presentAlertOnMainThread(
                    title: LocaleKeys.Error.alert.rawValue.locale(),
                    message: error.localizedDescription,
                    buttonTitle: LocaleKeys.Error.okButton.rawValue.locale())
                
            case .saveRecipe:
                Task {
                    await self.viewModel.saveRecipe(self.recipe)
                }
                
            case .showImage(let url):
                let imageURL = URL(string: url)
                let processor = DownsamplingImageProcessor(size: imageView.bounds.size)
                |> RoundCornerImageProcessor(cornerRadius: 10)
                self.imageView.kf.setImage(
                    with: imageURL,
                    placeholder: Images.background,
                    options: [
                        .processor(processor),
                        .scaleFactor(UIScreen.main.scale),
                        .transition(.fade(1)),
                        .cacheOriginalImage
                    ])
                
            case .successSave(let success):
                if success {
                    let alert = WhichFood.showAlert(title: LocaleKeys.DetailRecipe.success.rawValue.locale(),
                                                  message: LocaleKeys.DetailRecipe.savedSuccess.rawValue.locale(),
                                                  buttonTitle: LocaleKeys.DetailRecipe.okButton.rawValue.locale(), secondButtonTitle: nil, completionHandler: {
                        self.navigationController?.popToRootViewController(animated: true)
                    })
                    self.present(alert, animated: true)
                }
                
            case .loadingImage(let isLoading):
                if isLoading {
                    indicator.startAnimating()
                    imageView.isHidden = true
                } else {
                    indicator.stopAnimating()
                    imageView.isHidden = false
                }
            }
        }
    }
}

extension ShowFoodVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollOffset = scrollView.contentOffset.y
        updateNavBarAppearance(scrollOffset: scrollOffset)
        previousScrollOffset = scrollOffset
    }
}

extension UIBezierPath {
    static func checkmarkPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.width * 0.2, y: rect.height * 0.5))
        path.addLine(to: CGPoint(x: rect.width * 0.4, y: rect.height * 0.7))
        path.addLine(to: CGPoint(x: rect.width * 0.8, y: rect.height * 0.3))
        return path
    }
}
