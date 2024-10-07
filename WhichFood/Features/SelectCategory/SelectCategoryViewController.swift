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
        return button
    }()
    
    private lazy var selectLabel : UILabel = {
        let label = UILabel()
        label.text = LocaleKeys.SelectCategory.selectLabel.rawValue.locale()
        label.font = .preferredFont(forTextStyle: .headline)
        return label
    }()
    
    private lazy var chooseLabel : UILabel = {
        let label = UILabel()
        label.text = LocaleKeys.SelectCategory.chooseOneOrMore.rawValue.locale()
        label.font = .preferredFont(forTextStyle: .subheadline)
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
        
        NSLayoutConstraint.activate([
            nextButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor,constant: -view.bounds.height * 0.05),
            nextButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            
            nextButton.heightAnchor.constraint(equalToConstant: 50),
            nextButton.widthAnchor.constraint(equalToConstant: self.view.bounds.width * 0.8)
        ])
    }
    
    
    func setupProgressView() {
        view.addSubview(progressView)
        progressView.progressTintColor = .blue
        progressView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,constant: 0),
            progressView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 10),
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
        
        labelStack.spacing = 10
        
        labelStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            labelStack.topAnchor.constraint(equalTo: progressView.bottomAnchor,constant: 20),
            labelStack.leadingAnchor.constraint(equalTo: view.leadingAnchor,constant: view.bounds.width * 0.04 + 5)
        ])
    }
    
    
    func setupCollectionView() {
        let layout = CollectionViewFlowLayout()
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(CategoryCell.self, forCellWithReuseIdentifier: CategoryCell.identifier)
        collectionView.allowsMultipleSelection = true
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: labelStack.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: view.bounds.width * 0.04),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -view.bounds.width * 0.04),
            collectionView.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -10)
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
        viewModel.selectButton(index: indexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let text = viewModel.titles[indexPath.row].title
        let cellWidth = text.size(withAttributes:[.font: UIFont.systemFont(ofSize:17)]).width + 35
        return CGSize(width: cellWidth, height: 40.0)
    }
    
    
}
