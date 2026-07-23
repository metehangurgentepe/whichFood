//
//  SelectCategoryViewController.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 13.03.2024.
//

import UIKit



class SelectCategoryViewController: UIViewController, SelectCategoryVCDelegate {
    private lazy var nextButton : UIButton = {
        let button = UIButton()
        button.setTitle(LocaleKeys.SelectCategory.nextButton.rawValue.locale(), for: .normal)
        button.backgroundColor = Colors.primary.color
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)

        // Add shadow for depth
        button.layer.shadowColor = Colors.primary.color.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 12
        button.layer.shadowOpacity = 0.3

        return button
    }()
    
    private lazy var selectLabel : UILabel = {
        let label = UILabel()
        label.text = LocaleKeys.SelectCategory.selectLabel.rawValue.locale()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .label
        return label
    }()

    private lazy var chooseLabel : UILabel = {
        let label = UILabel()
        label.text = LocaleKeys.SelectCategory.chooseOneOrMore.rawValue.locale()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()
    let labelStack = UIStackView()
    let progressView = UIProgressView()
    var collectionView: UICollectionView!
    
    var viewModel = SelectCategoryViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupProgressView()
        setupLabels()
        setupNextButton()
        animateProgressView()
        setupCollectionView()
        viewModel.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        view.backgroundColor = .systemBackground
    }
    
    
    @objc func nextButtonClicked() {
        let vc = SelectFoodViewController()
        let selected = viewModel.titles.filter({ $0.isSelected == true })
        vc.categories = selected.map{ $0.title }
        print(vc.categories)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    func setupNextButton() {
        view.addSubview(nextButton)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(nextButtonClicked), for: .touchUpInside)

        // Add touch feedback
        nextButton.addTarget(self, action: #selector(buttonTouchDown), for: .touchDown)
        nextButton.addTarget(self, action: #selector(buttonTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        NSLayoutConstraint.activate([
            nextButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            nextButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            nextButton.heightAnchor.constraint(equalToConstant: 56),
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    @objc func buttonTouchDown() {
        UIView.animate(withDuration: 0.1) {
            self.nextButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }

    @objc func buttonTouchUp() {
        UIView.animate(withDuration: 0.1) {
            self.nextButton.transform = CGAffineTransform.identity
        }
    }
    
    
    func setupProgressView() {
        view.addSubview(progressView)

        // Modern progress view styling
        progressView.progressTintColor = Colors.primary.color
        progressView.trackTintColor = Colors.primary.color.withAlphaComponent(0.2)
        progressView.layer.cornerRadius = 6
        progressView.clipsToBounds = true

        progressView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            progressView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 12),
            progressView.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.9)
        ])
    }
    
    
    func animateProgressView() {
        self.progressView.setProgress(0, animated: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.progressView.setProgress(0.5, animated: false)
            UIView.animate(withDuration: 2, delay: 0, options: [], animations: { [unowned self] in
                self.progressView.layoutIfNeeded()
            })
        }
    }
    
    
    func setupLabels() {
        view.addSubview(labelStack)

        labelStack.axis = .vertical
        labelStack.addArrangedSubview(selectLabel)
        labelStack.addArrangedSubview(chooseLabel)
        labelStack.spacing = 8
        labelStack.alignment = .leading

        labelStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            labelStack.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 32),
            labelStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            labelStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }
    
    
    func setupCollectionView() {
        let layout = CollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 16

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(CategoryCell.self, forCellWithReuseIdentifier: CategoryCell.identifier)
        collectionView.allowsMultipleSelection = true
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: labelStack.bottomAnchor, constant: 24),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            collectionView.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -20)
        ])
    }
    

}

extension SelectCategoryViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.titles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCell.identifier, for: indexPath) as! CategoryCell
        cell.configure(title: viewModel.titles[indexPath.row].title)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        viewModel.selectButton(index: indexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let text = viewModel.titles[indexPath.row].title
        let cellWidth = text.size(withAttributes:[.font: UIFont.systemFont(ofSize: 16, weight: .medium)]).width + 40
        return CGSize(width: cellWidth, height: 44.0)
    }
    
    
}
