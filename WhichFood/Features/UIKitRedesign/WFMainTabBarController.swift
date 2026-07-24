import UIKit
import SwiftUI
import Combine

/// UIKit root of the app, replacing the SwiftUI `WhichFoodMainView` shell.
///
/// Owns the shared `WhichFoodAppState` and all cross-tab navigation: recipe
/// creation, the photo picker, recipe detail and error reporting.
final class WFMainTabBarController: UITabBarController {

    private let appState: WhichFoodAppState
    private let isPremium: Bool
    private var cancellables = Set<AnyCancellable>()
    /// When set, the app state is pre-populated (screenshot mode) and `loadAll`
    /// is skipped so mock data isn't overwritten by network results.
    private let usesInjectedState: Bool

    init(isPremium: Bool = false, screenshotState: WhichFoodAppState? = nil) {
        self.isPremium = isPremium
        self.appState = screenshotState ?? WhichFoodAppState()
        self.usesInjectedState = screenshotState != nil
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureAppearance()
        configureTabs()
        observeErrors()

        if !usesInjectedState {
            Task { await appState.loadAll() }
        }
    }

    #if DEBUG
    /// A recipe to auto-present as detail once the tab bar is on screen.
    var pendingScreenshotDetail: RecipeResponseModel?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let recipe = pendingScreenshotDetail {
            pendingScreenshotDetail = nil
            openRecipe(recipe)
        }
    }
    #endif

    // MARK: - Setup

    private func configureAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        // Not `.withAlphaComponent` — that resolves a dynamic colour against the
        // current trait and freezes it, breaking dark mode.
        appearance.backgroundColor = WFUIPalette.background
        appearance.shadowColor = WFUIPalette.border

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = WFUIPalette.orange
        tabBar.unselectedItemTintColor = WFUIPalette.inactive
    }

    private func configureTabs() {
        let home = WFHomeViewController(
            appState: appState,
            createFromIngredients: { [weak self] in self?.startCreation(mode: .ingredients) },
            createFromPhoto: { [weak self] in self?.presentPhotoSource() },
            createFromPrompt: { [weak self] text in self?.startCreation(mode: .prompt(text)) },
            openRecipe: { [weak self] recipe in self?.openRecipe(recipe) }
        )
        home.tabBarItem = UITabBarItem(title: "Home".locale(), image: UIImage(systemName: "house"), tag: 0)

        // Still SwiftUI; hosted until each is ported to UIKit in turn.
        let favorites = hosting(
            WFFavoritesView(appState: appState, openRecipe: { [weak self] in self?.openRecipe($0) }),
            title: "Favorites".locale(),
            systemImage: "heart",
            tag: 1
        )

        let discoverVC = WFDiscoverViewController(
            appState: appState,
            openRecipe: { [weak self] recipe in self?.openRecipe(recipe) }
        )
        let discover = UINavigationController(rootViewController: discoverVC)
        discover.tabBarItem = UITabBarItem(title: "Search".locale(), image: UIImage(systemName: "magnifyingglass"), tag: 2)

        let settings = hosting(
            WFSettingsHandoffView(appState: appState, premiumFromLaunch: isPremium),
            title: "Settings".locale(),
            systemImage: "gearshape",
            tag: 3
        )

        viewControllers = [home, favorites, discover, settings]
    }

    private func hosting<Content: View>(
        _ view: Content,
        title: String,
        systemImage: String,
        tag: Int
    ) -> UIViewController {
        let controller = UIHostingController(rootView: view)
        controller.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: systemImage), tag: tag)
        return controller
    }

    private func observeErrors() {
        appState.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in self?.presentError(message) }
            .store(in: &cancellables)
    }

    // MARK: - Navigation

    private func openRecipe(_ recipe: RecipeResponseModel) {
        let detail = WFRecipeDetailViewController(
            recipe: recipe,
            isSaved: true,
            appState: appState,
            close: { [weak self] in self?.dismiss(animated: true) }
        )

        let navigation = UINavigationController(rootViewController: detail)
        navigation.modalPresentationStyle = .fullScreen
        navigation.navigationBar.isTranslucent = true
        present(navigation, animated: true)
    }

    private func startCreation(mode: WFRecipeCreationMode) {
        let flow = WFCreationFlowController(mode: mode, appState: appState)
        flow.modalPresentationStyle = .fullScreen

        present(flow, animated: true)
    }

    private func presentPhotoSource() {
        let sheet = WFPhotoSourceSheetViewController { [weak self] source in
            // Wait for the sheet to be gone before bringing the picker up
            self?.dismiss(animated: true) {
                self?.presentImagePicker(source: source)
            }
        }

        sheet.modalPresentationStyle = .pageSheet
        if let presentation = sheet.sheetPresentationController {
            presentation.detents = [.medium()]
            presentation.prefersGrabberVisible = true
            presentation.preferredCornerRadius = 26
        }
        present(sheet, animated: true)
    }

    private func presentImagePicker(source: UIImagePickerController.SourceType) {
        // The camera path uses our own scanning UI; the library keeps the system picker.
        guard source != .camera else {
            presentCameraScanner()
            return
        }

        guard UIImagePickerController.isSourceTypeAvailable(source) else { return }

        let picker = UIImagePickerController()
        picker.sourceType = source
        picker.delegate = self
        present(picker, animated: true)
    }

    private func presentCameraScanner() {
        let scanner = WFCameraScanViewController(
            onCapture: { [weak self] image in
                self?.dismiss(animated: true) {
                    self?.startCreation(mode: .photo(image))
                }
            },
            onCancel: { [weak self] in self?.dismiss(animated: true) }
        )
        scanner.modalPresentationStyle = .fullScreen
        present(scanner, animated: true)
    }

    private func presentError(_ message: String) {
        let alert = UIAlertController(
            title: "Something went wrong".locale(),
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK".locale(), style: .cancel) { [weak self] _ in
            self?.appState.errorMessage = nil
        })

        // Don't stack an alert on top of whatever is already showing
        (presentedViewController ?? self).present(alert, animated: true)
    }
}

// MARK: - Photo source sheet

/// Bottom sheet asking where the photo should come from.
final class WFPhotoSourceSheetViewController: UIViewController {

    private let choose: (UIImagePickerController.SourceType) -> Void

    init(choose: @escaping (UIImagePickerController.SourceType) -> Void) {
        self.choose = choose
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = WFUIPalette.background

        let titleLabel = UILabel()
        titleLabel.text = "Add a photo".locale()
        titleLabel.font = WFUIFont.heading(20, weight: .bold)
        titleLabel.textColor = WFUIPalette.text

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Snap a dish or pick one from your library.".locale()
        subtitleLabel.font = WFUIFont.body(13)
        subtitleLabel.textColor = WFUIPalette.secondaryText
        subtitleLabel.numberOfLines = 0

        let header = UIStackView.wf(axis: .vertical, spacing: 4, views: [titleLabel, subtitleLabel])

        var options: [UIView] = []
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            options.append(makeOption(
                title: "Take a photo".locale(),
                subtitle: "Use the camera".locale(),
                icon: "camera.fill",
                source: .camera
            ))
        }
        options.append(makeOption(
            title: "Choose from library".locale(),
            subtitle: "Pick an existing photo".locale(),
            icon: "photo.on.rectangle",
            source: .photoLibrary
        ))

        let stack = UIStackView.wf(axis: .vertical, spacing: 10, views: options)

        view.addSubview(header)
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.topAnchor, constant: 28),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            stack.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func makeOption(
        title: String,
        subtitle: String,
        icon: String,
        source: UIImagePickerController.SourceType
    ) -> UIView {
        let button = WFUIPhotoSourceOptionView(title: title, subtitle: subtitle, icon: icon) { [weak self] in
            self?.choose(source)
        }
        button.heightAnchor.constraint(equalToConstant: 68).isActive = true
        return button
    }
}

private final class WFUIPhotoSourceOptionView: UIControl {
    private let action: () -> Void

    init(title: String, subtitle: String, icon: String, action: @escaping () -> Void) {
        self.action = action
        super.init(frame: .zero)

        backgroundColor = WFUIPalette.card
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = WFUIPalette.border.cgColor

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = WFUIPalette.orange
        iconView.contentMode = .center
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
        iconView.backgroundColor = WFUIPalette.selectedBackground
        iconView.layer.cornerRadius = 12
        iconView.clipsToBounds = true
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = WFUIFont.heading(14.5, weight: .bold)
        titleLabel.textColor = WFUIPalette.text

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = WFUIFont.body(11.5)
        subtitleLabel.textColor = WFUIPalette.secondaryText

        let textStack = UIStackView.wf(axis: .vertical, spacing: 2, alignment: .leading, views: [
            titleLabel, subtitleLabel
        ])

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = WFUIPalette.tertiaryText
        chevron.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)

        let row = UIStackView.wf(axis: .horizontal, spacing: 14, alignment: .center, views: [
            iconView, textStack, UIView(), chevron
        ])
        row.isUserInteractionEnabled = false
        addSubview(row)

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40)
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

// MARK: - Image picker

extension WFMainTabBarController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)

        picker.dismiss(animated: true) { [weak self] in
            guard let self, let image else { return }
            self.startCreation(mode: .photo(image))
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
