//
//  HomeViewController.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 11.09.2023.
//

import UIKit
import SkeletonView
import FirebaseFirestore
import SwiftUI
import RevenueCat
import SDWebImage


class HomeViewController: DataLoadingVC, HomeRecipeCellDelegate{
    
    enum Section {
        case main
    }
    
    private lazy var nextButton: UIButton = {
        let button = UIButton()
        let plusConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .heavy)
        let plusImage = UIImage(systemName: "plus", withConfiguration: plusConfig)?.withTintColor(.white, renderingMode: .alwaysOriginal)
        button.setImage(plusImage, for: .normal)
        button.backgroundColor = Colors.primary.color
        button.setTitle(NSLocalizedString(LocaleKeys.Home.button.rawValue, comment:"button"), for: .normal)
        button.layer.cornerRadius = 22
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        return button
    }()

    private lazy var photoRecipeCard: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.label.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 8
        view.isUserInteractionEnabled = true

        // Add tap gesture with highlight effect
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(photoRecipeCardTapped))
        tapGesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGesture)

        // Add long press for visual feedback
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(cardPressed(_:)))
        longPress.minimumPressDuration = 0.3
        view.addGestureRecognizer(longPress)

        return view
    }()

    private lazy var photoRecipeImageView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        containerView.layer.cornerRadius = 12

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.image = UIImage(systemName: "camera.fill")
        imageView.tintColor = .systemBlue
        imageView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.5),
            imageView.heightAnchor.constraint(equalTo: containerView.heightAnchor, multiplier: 0.5)
        ])

        return containerView
    }()

    private lazy var photoRecipeButton: UILabel = {
        let label = UILabel()
        label.text = LocaleKeys.Home.photoRecipeTitle.rawValue.locale()
        label.textColor = .systemBlue
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 0
        return label
    }()

    private lazy var photoRecipeLabel: UILabel = {
        let label = UILabel()
        label.text = LocaleKeys.Home.photoRecipeDesc.rawValue.locale()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        return label
    }()

    private lazy var generateImageCard: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.label.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 8
        view.isUserInteractionEnabled = true

        // Add tap gesture with highlight effect
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(generateImageCardTapped))
        tapGesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGesture)

        // Add long press for visual feedback
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(cardPressed(_:)))
        longPress.minimumPressDuration = 0.3
        view.addGestureRecognizer(longPress)

        return view
    }()

    private lazy var generateImageImageView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = .systemOrange.withAlphaComponent(0.1)
        containerView.layer.cornerRadius = 12

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.image = UIImage(systemName: "list.bullet.rectangle")
        imageView.tintColor = .systemOrange
        imageView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.5),
            imageView.heightAnchor.constraint(equalTo: containerView.heightAnchor, multiplier: 0.5)
        ])

        return containerView
    }()

    private lazy var generateImageButton: UILabel = {
        let label = UILabel()
        label.text = LocaleKeys.Home.ingredientRecipeTitle.rawValue.locale()
        label.textColor = .systemOrange
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 0
        return label
    }()

    private lazy var generateImageLabel: UILabel = {
        let label = UILabel()
        label.text = LocaleKeys.Home.ingredientRecipeDesc.rawValue.locale()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        return label
    }()
    
    private lazy var categoryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 70, height: 35)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(CategoryButtonCell.self, forCellWithReuseIdentifier: CategoryButtonCell.identifier)
        return collectionView
    }()
    
    var recipeCollectionView: UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<Section, Recipe>!
    
    lazy var viewModel = HomeViewModel()
    weak var delegate : HomeViewModelDelegate?
    var recipes = [Recipe]()
    let categories = Categories.homeCategoryList
    var categoryIndexPath: IndexPath?

    // Constraint'leri tutmak için
    var photoCardTopConstraint: NSLayoutConstraint!
    var generateCardTopConstraint: NSLayoutConstraint!
    var categoryCollectionViewTopConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        viewModel.delegate = self
        recipeCollectionView.delegate = self
        configureDataSource()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        removeNavigationBarSeparator()
        if categoryIndexPath != nil {
            categoryCollectionView.deselectItem(at: categoryIndexPath!, animated: true)
        }
        viewModel.getRecipes()
    }
    
    private func showPhotoSourceBottomSheet() {
        print("🔵 showPhotoSourceBottomSheet called!")

        let alert = UIAlertController(title: LocaleKeys.Home.photoSourceTitle.rawValue.locale(),
                                     message: nil,
                                     preferredStyle: .actionSheet)

        // Kamera seçeneği
        let cameraAction = UIAlertAction(title: LocaleKeys.Home.photoSourceCamera.rawValue.locale(),
                                        style: .default) { _ in
            print("📷 Camera action selected!")
            self.goToCamera()
        }
        cameraAction.setValue(UIImage(systemName: "camera.fill"), forKey: "image")

        // Galeri seçeneği
        let galleryAction = UIAlertAction(title: LocaleKeys.Home.photoSourceGallery.rawValue.locale(),
                                         style: .default) { _ in
            print("📸 Gallery action selected!")
            self.goToPhotoLibrary()
        }
        galleryAction.setValue(UIImage(systemName: "photo.on.rectangle"), forKey: "image")

        // İptal seçeneği
        let cancelAction = UIAlertAction(title: LocaleKeys.Home.photoSourceCancel.rawValue.locale(),
                                        style: .cancel)

        alert.addAction(cameraAction)
        alert.addAction(galleryAction)
        alert.addAction(cancelAction)

        // iPad için popover ayarları
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        present(alert, animated: true)
    }

    @objc func showPhotoSourceSelection() {
        showPhotoSourceBottomSheet()
    }

    @objc func showCameraAlert() {
        let alert = WhichFood.showAlert(title: LocaleKeys.Home.cameraAlertTitle.rawValue.locale(),
                              message: LocaleKeys.Home.cameraAlertMessage.rawValue.locale(),
                              buttonTitle: LocaleKeys.Error.backButton.rawValue.locale(),
                              secondButtonTitle: LocaleKeys.Error.okButton.rawValue.locale(),
                              completionHandler: {
        }, completionSecondHandler: {
            self.goToCamera()
        }
        )
        self.present(alert, animated: true)
    }
    
    
    func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource(collectionView: recipeCollectionView, cellProvider: { collectionView, indexPath, follower in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeRecipeCell.identifier, for: indexPath) as! HomeRecipeCell
            let recipe = self.recipes[indexPath.row]
            cell.configure(recipe: recipe)
            cell.delegate = self
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
    
    
    @objc func goToCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        viewModel.delegate?.navigate(to: .present(imagePicker))
    }

    private func goToPhotoLibrary() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true)
    }
    
    
    @objc func goToPremium() {
        let subscriptionView = PremiumVC()
        subscriptionView.modalPresentationStyle = .fullScreen
        present(subscriptionView, animated: true)
    }

    @objc func photoRecipeCardTapped() {
        print("🟢 Photo recipe card tapped!")

        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        showPhotoSourceBottomSheet()
    }

    @objc func generateImageCardTapped() {
        print("🟠 Generate image card tapped!")

        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        // Malzeme seçimi ekranına git (create new recipe float butonuna tıklayınca olan)
        let vc = SelectCategoryViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    // Keep old methods for backward compatibility if needed elsewhere
    @objc func photoRecipeButtonTapped() {
        photoRecipeCardTapped()
    }

    @objc func generateImageButtonTapped() {
        generateImageCardTapped()
    }

    @objc func cardPressed(_ gesture: UILongPressGestureRecognizer) {
        guard let view = gesture.view else { return }

        print("🔥 Card pressed gesture triggered - state: \(gesture.state.rawValue)")

        switch gesture.state {
        case .began:
            print("🔥 Card press began")
            UIView.animate(withDuration: 0.1) {
                view.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                view.alpha = 0.8
            }
        case .ended, .cancelled:
            print("🔥 Card press ended/cancelled")
            UIView.animate(withDuration: 0.1) {
                view.transform = CGAffineTransform.identity
                view.alpha = 1.0
            }
        default:
            break
        }
    }

    private func showRecipeContent() {
        recipeCollectionView.isHidden = false
        categoryCollectionView.isHidden = false
        nextButton.isHidden = false
        // Tarif varsa fotoğraf kartlarını gizle
        photoRecipeCard.isHidden = true
        generateImageCard.isHidden = true

        // Category collection view'i en üste taşı
        categoryCollectionViewTopConstraint.isActive = false
        categoryCollectionViewTopConstraint = categoryCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16)
        categoryCollectionViewTopConstraint.isActive = true

        view.layoutIfNeeded()
    }

    private func hideRecipeContent() {
        recipeCollectionView.isHidden = true
        categoryCollectionView.isHidden = true
        nextButton.isHidden = true
        // Tarif yoksa fotoğraf kartlarını göster ve ortala
        photoRecipeCard.isHidden = false
        generateImageCard.isHidden = false

        // Category collection view'i kartların altına geri al
        categoryCollectionViewTopConstraint.isActive = false
        categoryCollectionViewTopConstraint = categoryCollectionView.topAnchor.constraint(equalTo: generateImageCard.bottomAnchor, constant: 16)
        categoryCollectionViewTopConstraint.isActive = true

        centerPhotoCards()
    }

    private func centerPhotoCards() {
        // Mevcut constraint'leri deaktive et
        photoCardTopConstraint.isActive = false
        generateCardTopConstraint.isActive = false

        // Yeni constraint'leri oluştur (merkezi konumlandırma)
        let centerY = view.safeAreaLayoutGuide.centerYAnchor
        photoCardTopConstraint = photoRecipeCard.centerYAnchor.constraint(equalTo: centerY, constant: -60)
        generateCardTopConstraint = generateImageCard.centerYAnchor.constraint(equalTo: centerY, constant: 60)

        photoCardTopConstraint.isActive = true
        generateCardTopConstraint.isActive = true

        view.layoutIfNeeded()
    }

    private func resetPhotoCardsToTop() {
        // Mevcut constraint'leri deaktive et
        photoCardTopConstraint.isActive = false
        generateCardTopConstraint.isActive = false

        // Orijinal constraint'leri geri yükle
        photoCardTopConstraint = photoRecipeCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16)
        generateCardTopConstraint = generateImageCard.topAnchor.constraint(equalTo: photoRecipeCard.bottomAnchor, constant: 16)

        photoCardTopConstraint.isActive = true
        generateCardTopConstraint.isActive = true

        view.layoutIfNeeded()
    }

    
    
    private func configure() {
        navigationItem.largeTitleDisplayMode = .always
        self.view.backgroundColor = .systemBackground
        title = LocaleKeys.Home.recipe.rawValue.locale()
        
        categoryCollectionView.delegate = self
        categoryCollectionView.dataSource = self
        
        navigationItem.hidesBackButton = true
        removeNavigationBarSeparator()
        
        connfigureDiscoverRecipeBarButton()
        settingsButton()
        setupPhotoRecipeCard()
        setupGenerateImageCard()
        setupCategoryButtons()
        configureCollectionView()
        setUpButton()
    }
    
    private func removeNavigationBarSeparator() {
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.shadowColor = .clear
            appearance.shadowImage = UIImage()
            
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
            navigationController?.navigationBar.compactAppearance = appearance
        } else {
            navigationController?.navigationBar.shadowImage = UIImage()
            navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        }
        
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
    }
    
    
    @objc func navigateToDiscoverScreen() {
        Task{
            try await viewModel.increaseApiUsage()
        }
    }
    
    
    @objc func didTapButton() {
        UIView.animate(withDuration: 0.1, animations: {
            self.nextButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            self.nextButton.alpha = 0.5
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.nextButton.transform = CGAffineTransform.identity
                self.nextButton.alpha = 1
            }
        }
        let vc = SelectCategoryViewController()
        vc.hidesBottomBarWhenPushed = true
        viewModel.delegate?.navigate(to: .goToVC(vc))
    }
}

extension HomeViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            let vc = ImageToTextVC()
            vc.takenImage = selectedImage
            picker.dismiss(animated: true) {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}

// MARK: Design Extension
extension HomeViewController {
    func configureCollectionView() {
        recipeCollectionView = UICollectionView(frame: .zero, collectionViewLayout: UIHelper.createTwoColumntFlowLayout(in: view))
        
        view.addSubview(recipeCollectionView)
        recipeCollectionView.backgroundColor = .systemBackground
        recipeCollectionView.register(HomeRecipeCell.self, forCellWithReuseIdentifier: HomeRecipeCell.identifier)
        recipeCollectionView.prefetchDataSource = self
        recipeCollectionView.isPrefetchingEnabled = true


        
        recipeCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            recipeCollectionView.topAnchor.constraint(equalTo: categoryCollectionView.bottomAnchor, constant: 5),
            recipeCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            recipeCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            recipeCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
    
    private func setUpButton() {
        self.view.addSubview(nextButton)
        
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nextButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            nextButton.heightAnchor.constraint(equalToConstant: 44),
            nextButton.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.4),
            nextButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12)
        ])
    }
    
    
    private func setupPhotoRecipeCard() {
        view.addSubview(photoRecipeCard)
        photoRecipeCard.addSubview(photoRecipeImageView)
        photoRecipeCard.addSubview(photoRecipeButton)
        photoRecipeCard.addSubview(photoRecipeLabel)

        photoRecipeCard.translatesAutoresizingMaskIntoConstraints = false
        photoRecipeImageView.translatesAutoresizingMaskIntoConstraints = false
        photoRecipeButton.translatesAutoresizingMaskIntoConstraints = false
        photoRecipeLabel.translatesAutoresizingMaskIntoConstraints = false

        // Initial constraint'i sakla
        photoCardTopConstraint = photoRecipeCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16)

        NSLayoutConstraint.activate([
            // Card constraints
            photoCardTopConstraint,
            photoRecipeCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            photoRecipeCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            photoRecipeCard.heightAnchor.constraint(equalToConstant: 100),

            // ImageView constraints
            photoRecipeImageView.leadingAnchor.constraint(equalTo: photoRecipeCard.leadingAnchor, constant: 16),
            photoRecipeImageView.centerYAnchor.constraint(equalTo: photoRecipeCard.centerYAnchor),
            photoRecipeImageView.widthAnchor.constraint(equalToConstant: 60),
            photoRecipeImageView.heightAnchor.constraint(equalToConstant: 60),

            // Button constraints
            photoRecipeButton.topAnchor.constraint(equalTo: photoRecipeCard.topAnchor, constant: 20),
            photoRecipeButton.leadingAnchor.constraint(equalTo: photoRecipeImageView.trailingAnchor, constant: 16),
            photoRecipeButton.trailingAnchor.constraint(equalTo: photoRecipeCard.trailingAnchor, constant: -16),

            // Label constraints
            photoRecipeLabel.topAnchor.constraint(equalTo: photoRecipeButton.bottomAnchor, constant: 4),
            photoRecipeLabel.leadingAnchor.constraint(equalTo: photoRecipeImageView.trailingAnchor, constant: 16),
            photoRecipeLabel.trailingAnchor.constraint(equalTo: photoRecipeCard.trailingAnchor, constant: -16),
        ])
    }

    private func setupGenerateImageCard() {
        view.addSubview(generateImageCard)
        generateImageCard.addSubview(generateImageImageView)
        generateImageCard.addSubview(generateImageButton)
        generateImageCard.addSubview(generateImageLabel)

        generateImageCard.translatesAutoresizingMaskIntoConstraints = false
        generateImageImageView.translatesAutoresizingMaskIntoConstraints = false
        generateImageButton.translatesAutoresizingMaskIntoConstraints = false
        generateImageLabel.translatesAutoresizingMaskIntoConstraints = false

        // Initial constraint'i sakla
        generateCardTopConstraint = generateImageCard.topAnchor.constraint(equalTo: photoRecipeCard.bottomAnchor, constant: 16)

        NSLayoutConstraint.activate([
            // Card constraints
            generateCardTopConstraint,
            generateImageCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            generateImageCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            generateImageCard.heightAnchor.constraint(equalToConstant: 100),

            // ImageView constraints
            generateImageImageView.leadingAnchor.constraint(equalTo: generateImageCard.leadingAnchor, constant: 16),
            generateImageImageView.centerYAnchor.constraint(equalTo: generateImageCard.centerYAnchor),
            generateImageImageView.widthAnchor.constraint(equalToConstant: 60),
            generateImageImageView.heightAnchor.constraint(equalToConstant: 60),

            // Button constraints
            generateImageButton.topAnchor.constraint(equalTo: generateImageCard.topAnchor, constant: 20),
            generateImageButton.leadingAnchor.constraint(equalTo: generateImageImageView.trailingAnchor, constant: 16),
            generateImageButton.trailingAnchor.constraint(equalTo: generateImageCard.trailingAnchor, constant: -16),

            // Label constraints
            generateImageLabel.topAnchor.constraint(equalTo: generateImageButton.bottomAnchor, constant: 4),
            generateImageLabel.leadingAnchor.constraint(equalTo: generateImageImageView.trailingAnchor, constant: 16),
            generateImageLabel.trailingAnchor.constraint(equalTo: generateImageCard.trailingAnchor, constant: -16),
        ])
    }

    private func setupCategoryButtons() {
        view.addSubview(categoryCollectionView)

        categoryCollectionView.translatesAutoresizingMaskIntoConstraints = false

        // Initial constraint'i sakla - empty state için kartların altında olacak
        categoryCollectionViewTopConstraint = categoryCollectionView.topAnchor.constraint(equalTo: generateImageCard.bottomAnchor, constant: 16)

        NSLayoutConstraint.activate([
            categoryCollectionViewTopConstraint,
            categoryCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor,constant: 20),
            categoryCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor,constant: 0),
            categoryCollectionView.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    
    private func connfigureDiscoverRecipeBarButton() {
        let image = SFSymbols.wandAndStars!.withRenderingMode(.alwaysTemplate).withTintColor(.gray)
        let discoverButton = UIBarButtonItem(image: image, style: .done, target: self, action: #selector(navigateToDiscoverScreen))
        discoverButton.tintColor = UIColor(Color.primary)
        navigationItem.leftBarButtonItem = discoverButton
    }
    
    
    private func settingsButton() {
        let cameraButton = UIBarButtonItem(
            image: UIImage(systemName: "camera.fill"),
            style: .done,
            target: self,
            action: #selector(showPhotoSourceSelection)
        )
        
        cameraButton.tintColor = UIColor.orange
        
        let premiumButton = UIBarButtonItem(
            image: UIImage(named: "chef-hat-fill"),
            style: .done,
            target: self,
            action: #selector(goToPremium)
        )
        premiumButton.tintColor = UIColor(Color.primary)
        
        navigationItem.rightBarButtonItems = [
            cameraButton,
            premiumButton
        ]
    }
}

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryButtonCell.identifier, for: indexPath) as! CategoryButtonCell
        let category = categories[indexPath.item]
        cell.configure(title: category)
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch collectionView {
        case categoryCollectionView:
            let text = categories[indexPath.row]
            let cellWidth = text.size(withAttributes:[.font: UIFont.systemFont(ofSize:12)]).width + 25
            return CGSize(width: cellWidth, height: 30.0)
            
        case recipeCollectionView:
            return UIHelper.createTwoColumntFlowLayout(in: view).itemSize
            
        default:
            return CGSize()
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch collectionView {
        case recipeCollectionView:
            viewModel.delegate?.navigate(to: .details(indexPath.item))
            
        case categoryCollectionView:
            categoryIndexPath = indexPath
            let category = categories[indexPath.item]
            viewModel.filter(word: category)
            
        default:
            break
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            return self.makeContextMenu(for: indexPaths.first!)
        }
    }
    
    
    func makeContextMenu(for indexPath: IndexPath) -> UIMenu {
        let deleteAction = UIAction(title: LocaleKeys.Error.delete.rawValue.locale(), image: SFSymbols.deleteIcon) { _ in
            self.viewModel.deleteRecipe(recipe: self.recipes[indexPath.row])
            self.updatedData(on: self.recipes)
        }
        
        
        let shareAction = UIAction(title: LocaleKeys.Error.share.rawValue.locale(), image: SFSymbols.share) {[weak self] _ in
            guard let self = self else { return }
            
            let recipe = self.recipes[indexPath.row]
            
            let text = viewModel.createText(recipe: recipe)
            
            let activityViewController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
            
            if let popoverController = activityViewController.popoverPresentationController {
                popoverController.sourceView = self.view
                popoverController.sourceRect = self.view.bounds
            }
            self.present(activityViewController, animated: true, completion: nil)
        }
        
        let contextMenu = UIMenu(title: "", children: [deleteAction,shareAction])
        return contextMenu
    }
}

// MARK: DELEGATE EXTENSION
extension HomeViewController: HomeViewModelDelegate {
    func navigate(to navigationType: NavigationType) {
        DispatchQueue.main.async{ [weak self] in
            guard let self = self else { return }
            switch navigationType {
            case .details(let index):
                let vc = ShowFoodVC()
                vc.mode = .detail
                vc.recipe = self.viewModel.recipes[index].toRecipeResponseModel()
                self.navigationController?.pushViewController(vc, animated: true)
                
            case .goToVC(let vc):
                self.navigationController?.pushViewController(vc, animated: true)
                
            case .present(let vc):
                self.present(vc,animated:true)
            }
        }
    }
    
    
    func handleViewModelOutput(_ output: RecipeListViewModelOutput) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch output {
            case .setLoading(let isLoading):
                if isLoading {
                    self.customLoadingView()
                } else {
                    self.dismissLoadingView()
                }
                
            case .showRecipeList(let recipes):
                self.recipes = recipes
                updatedData(on: self.recipes)
                hideEmptyStateView(in: recipeCollectionView)
                showRecipeContent()

            case.emptyList:
                hideRecipeContent()
                // Empty state'te collection view yerine sadece kartlar gözükecek
                
            case .showError(let error):
                presentAlertOnMainThread(
                    title: LocaleKeys.Error.alert.rawValue.locale(),
                    message: error.localizedDescription,
                    buttonTitle: LocaleKeys.Error.okButton.rawValue.locale()
                )
            case .prepareRandomRecipe:
                let showFoodVC = ShowFoodVC()
                showFoodVC.mode = .random
                self.navigationController?.pushViewController(showFoodVC, animated: true)
            }
        }
    }
}


extension Recipe {
    func toRecipeResponseModel() -> RecipeResponseModel {
        return RecipeResponseModel(
            foodName: self.name,
            ingredients: self.ingredients ?? [],
            recipe: self.recipe ?? [],
            cookTime: self.cookTime ?? Date().description,
            prepTime: self.prepTime,
            totalTime: self.totalTime,
            difficulty: self.difficulty,
            servings: self.servings,
            description: self.description ?? "",
            type: self.type,
            cuisine: self.cuisine,
            allergens: self.allergens,
            tags: self.tags,
            cal: self.cal,
            nutritionalInfo: self.nutritionalInfo,
            tips: self.tips,
            imageURL: self.imageUrl
        )
    }
}

extension HomeViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        // Görüntüleri önceden yüklemek için görüntü URL'lerini al
        let urls = indexPaths.compactMap { indexPath -> URL? in
            guard indexPath.item < recipes.count else { return nil }
            guard let urlString = recipes[indexPath.item].imageUrl else { return nil }
            return URL(string: urlString)
        }
        
        // SDWebImage prefetch
        SDWebImagePrefetcher.shared.prefetchURLs(urls)
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        // Görüntü ön yüklemeyi iptal et
        let urls = indexPaths.compactMap { indexPath -> URL? in
            guard indexPath.item < recipes.count else { return nil }
            guard let urlString = recipes[indexPath.item].imageUrl else { return nil }
            return URL(string: urlString)
        }
        
        SDWebImagePrefetcher.shared.cancelPrefetching()
    }
}

// MARK: - HomeRecipeCellDelegate
extension HomeViewController {
    func deleteRecipe(recipe: Recipe) {
        viewModel.deleteRecipe(recipe: recipe)
    }

    func showError(error: Error) {
        presentAlertOnMainThread(
            title: LocaleKeys.Error.alert.rawValue.locale(),
            message: error.localizedDescription,
            buttonTitle: LocaleKeys.Error.okButton.rawValue.locale()
        )
    }

    func favoriteStatusChanged(recipe: Recipe) {
        // Find the cell for this recipe and refresh it
        if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
            let indexPath = IndexPath(item: index, section: 0)
            if let cell = recipeCollectionView.cellForItem(at: indexPath) as? HomeRecipeCell {
                cell.checkIsSaved(recipe: recipe)
            }
        }
    }
}
