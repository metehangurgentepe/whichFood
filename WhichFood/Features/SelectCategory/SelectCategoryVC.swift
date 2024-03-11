//
//  SelectCategoryVC.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 19.09.2023.
//

import UIKit

protocol SelectCategoryVCDelegate: AnyObject {
//    func nextButtonClicked()
//    func changeStateButton(button: UIButton)
}

class SelectCategoryVC: UIViewController, SelectCategoryVCDelegate {
    private lazy var nextButton : UIButton = {
        let button = UIButton()
        button.setTitle(NSLocalizedString(LocaleKeys.SelectCategory.nextButton.rawValue, comment:"Next Button"), for: .normal)
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
    let progressView = UIProgressView()
    var buttons : [UIButton] = []
    
    var viewModel = SelectCategoryViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        viewModel.delegate = self
        configure()
    }
    
    // MARK: Configure Design functions
    func configure() {
        setButtonTitles()
        setupNextButton()
        setupProgressView()
        animateProgressView()
        setupLabels()
    }
    
    @objc func nextButtonClicked() {
        let vc = SelectFoodViewController()
        let selected = buttons.filter({ $0.isSelected == true })
        vc.categories = selected.map{$0.currentTitle ?? ""}
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func changeStateButton(button: UIButton) {
        button.isSelected = !button.isSelected
        switch button.isSelected {
        case true:
            button.backgroundColor = Colors.accent.color
        case false:
            button.backgroundColor = Colors.accent.color.withAlphaComponent(0.3)
        }
    }
}
// MARK: Design Functions
extension SelectCategoryVC {
    func setupProgressView() {
        view.addSubview(progressView)
        progressView.progressTintColor = .blue
        progressView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.topAnchor,constant: view.bounds.height * 0.12),
            progressView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 10),
            progressView.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.9)
        ])
    }
    
    
    func setupLabels() {
        let stack = UIStackView()
        
        view.addSubview(stack)
        
        stack.axis = .vertical
        stack.addArrangedSubview(selectLabel)
        stack.addArrangedSubview(chooseLabel)
        
        stack.spacing = 10
        
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,constant: view.bounds.height * 0.05),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor,constant: view.bounds.width * 0.04 + 5)
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
    
    
    func setButtonTitles() {
        var stackViews: [UIStackView] = []
        var font : UIFont.TextStyle = .body
        
        if Bundle.main.preferredLocalizations.first ?? "Base" == "ru" || Bundle.main.preferredLocalizations.first ?? "Base" == "es" || Bundle.main.preferredLocalizations.first ?? "Base" == "it" || Bundle.main.preferredLocalizations.first ?? "Base" == "de" || Bundle.main.preferredLocalizations.first ?? "Base" == "fr" {
            font = .caption1
        }
        
        if Bundle.main.preferredLocalizations.first ?? "Base" == "en" || Bundle.main.preferredLocalizations.first ?? "Base" == "cs" {
            font = .callout
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            font = .largeTitle
        }
        
        for title in viewModel.titles {
            let button = CapsuleButton()
            button.setTitle(title.title, for: .normal)
            button.setTitleColor(.black, for: .normal)
            button.backgroundColor = Colors.accent.color.withAlphaComponent(0.3)
            button.titleLabel?.font = .preferredFont(forTextStyle: font)
            button.titleLabel?.numberOfLines = 2
            button.contentEdgeInsets = UIEdgeInsets(
                top: 10,
                left: 20,
                bottom: 10,
                right: 20)
            self.buttons.append(button)
            button.addTarget(self, action: #selector(changeStateButton), for: .touchUpInside)
        }
        
        for chunk in buttons.chunked(into: 3) {
            let stackView = UIStackView(arrangedSubviews: chunk)
            stackView.axis = .horizontal
            stackView.spacing = 18
            stackView.alignment = .center
            stackViews.append(stackView)
        }
        
        let verticalStackView = UIStackView(arrangedSubviews: stackViews)
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 10
        verticalStackView.alignment = .leading
        
        view.addSubview(verticalStackView)
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            verticalStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor,constant: view.bounds.width * 0.04),
            verticalStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: view.bounds.height * 0.13),
            verticalStackView.widthAnchor.constraint(equalToConstant: view.bounds.width - 40)
        ])
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
}
