//
//  PremiumVC.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 27.09.2023.
//

import UIKit
import RevenueCat


class PremiumVC: DataLoadingVC {
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.register(PremiumTableViewCell.self, forCellReuseIdentifier: PremiumTableViewCell.identifier)
        table.isHidden = true
        return table
    }()
    
    private lazy var progressViewContainer: UIView = {
        let container = UIView()
        container.backgroundColor = Colors.text.color
        container.layer.cornerRadius = 12
        return container
    }()
    
    private lazy var progressView : UIActivityIndicatorView = {
        let progressView = UIActivityIndicatorView()
        progressView.color = Colors.accent.color
        progressView.style = .large
        return progressView
    }()
    
    private lazy var checkIcon : UIImageView = {
        let imageview = UIImageView()
        imageview.image = Images.check
        imageview.contentMode = .scaleAspectFit
        return imageview
    }()
    
    private lazy var weekPriceLabel : UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .right
        label.font = .preferredFont(forTextStyle: .callout).withSize(14)
        label.isHidden = true
        return label
    }()
    
    private lazy var lifetimePriceLabel : UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .right
        label.font = .preferredFont(forTextStyle: .callout).withSize(14) // İstenilen yazı tipi ve boyutunu ayarlayın
        label.isHidden = true
        return label
    }()
    
    private lazy var continueButton: UIButton = {
        let button = UIButton()
        let title = NSLocalizedString(LocaleKeys.Premium.continueButton.rawValue, comment: "")
        button.setTitle(title, for: .normal)
        button.backgroundColor = Colors.accent.color
        button.layer.cornerRadius = 30
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.isHidden = true
        return button
    }()
    
    private lazy var weekButton: UIButton = {
        let button = UIButton()
        let title = NSLocalizedString(LocaleKeys.Premium.weekButton.rawValue, comment: "")
        button.setTitle(title, for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.setTitleColor(.white, for: .selected)
        button.backgroundColor =  UIColor(white: 1.2, alpha: 0.5)
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.isHidden = true
        return button
    }()
    
    private lazy var annualButton: UIButton = {
        let button = UIButton()
        let title = NSLocalizedString(LocaleKeys.Premium.lifetimeButton.rawValue, comment: "")
        button.setTitle(title, for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.setTitleColor(.white, for: .selected)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.backgroundColor =  UIColor(white: 1.2, alpha: 0.5)
        button.layer.cornerRadius = 12
        button.isHidden = true
        return button
    }()
    
    private lazy var premiumText : UILabel = {
        let label = UILabel()
        label.text = "\(LocaleKeys.Settings.premium.rawValue.locale()) 🎉"
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .headline)
        return label
    }()
    
    private lazy var premiumLabel : UILabel = {
        let label = UILabel()
        label.text = LocaleKeys.Premium.subscribed.rawValue.locale()
        label.isHidden = true
        label.textAlignment = .center
        if let customFont = UIFont(name: "MontserratRoman-Bold", size: 40) {
            label.font = customFont
        } else {
            label.font = .preferredFont(forTextStyle: .headline).withSize(40)
        }
        return label
    }()
    
    private lazy var premiumLabelSubheadline : UILabel = {
        let label = UILabel()
        label.text = LocaleKeys.Premium.subscribedSubheadline.rawValue.locale()
        label.isHidden = true
        label.numberOfLines = 5
        label.font = .preferredFont(forTextStyle: .headline).withSize(14)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var exitButton : UIButton = {
        let button = UIButton()
        button.setImage(Images.exit, for: .normal)
        button.tintColor = .white
        return button
    }()
    
    private lazy var stackButton: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        return stack
    }()
    
    private lazy var premiumPhoto: UIImageView = {
        let imageView = UIImageView()
        let size = CGSize(width: view.bounds.height * 0.4, height: view.bounds.width * 0.4)
        imageView.image = UIImage(resource: .recipe)
        //            .resize(toSize: size)
        return imageView
    }()
    
    private lazy var latestExpirationDateLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .white
        label.textAlignment = .left
        return label
    }()
    
    private lazy var termsOfServiceButton: UIButton = {
        let button = UIButton()
        button.setTitle("Terms Of Service", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .caption1)
        button.addTarget(self, action: #selector(tappedTermsOfServiceButton), for: .touchUpInside)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    private lazy var privacyPolicyButton: UIButton = {
        let button = UIButton()
        button.setTitle("Privacy Policy", for: .normal)
        button.addTarget(self, action: #selector(tappedPrivacyPoliceButton), for: .touchUpInside)
        button.titleLabel?.font = .preferredFont(forTextStyle: .caption1)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    private lazy var restorePurchasesButton: UIButton = {
        let button = UIButton()
        button.setTitle("Restore purchases", for: .normal)
        button.addTarget(self, action: #selector(tappedRestorePurchasesButton), for: .touchUpInside)
        button.titleLabel?.font = .preferredFont(forTextStyle: .caption1)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    private lazy var closePage = UIAction { action in
        self.dismiss(animated: true, completion: nil)
    }
    
    var properties: [Property] = []
    var isSelected: Bool = false
    var offering : Offering?
    var viewModel = PremiumViewModel()
    
    var packages = [Package]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Premium"
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        configure()
        tapWeekButton()
        viewModel.delegate = self
        viewModel.getCustomerInfo()
        viewModel.fetchPackage()
    }
    
    func configure() {
        setupBackgroundImage()
        view.addSubview(continueButton)
        setupButtons()
        setupContinueButton()
        setupWeekPriceLabel()
        setupLifetimeIcon()
        setupLifetimePriceLabel()
        setupTable()
        addProperties()
        setupPremiumLabel()
        setupExitButton()
        setupIndicator()
        setupPremiumPhoto()
        setupPremiumSubheadlineLabel()
        setupLatestExpirationDateLabel()
        setupPremiumButtons()
        setupPremiumText()
        progressViewContainer.isHidden = true
        progressView.isHidden = true
    }
    
    func restorePurchases() {
        Purchases.shared.restorePurchases{ info, error in
            guard let info = info, error == nil else {return}
        }
    }
    
    @objc private func didTapSubscribe() {
        if weekButton.isSelected {
            if let weeklyOffering = self.offering?.weekly {
                Task{
                    try await self.viewModel.purchase(package: (weeklyOffering))
                }
            }
            
        } else if annualButton.isSelected {
            if let annualOffering = self.offering?.annual {
                Task{
                    try await self.viewModel.purchase(package: (annualOffering))
                }
            }
        }
    }
    
    @objc func tapWeekButton() {
        weekButton.isSelected = true
        annualButton.isSelected = false
        
        UIView.animate(withDuration: 0.3) {
            self.weekButton.backgroundColor = .black
            self.weekButton.layer.borderColor = Colors.opacWhite.color.cgColor
            self.weekButton.layer.borderWidth = 2
            self.annualButton.layer.borderWidth = 0
            self.annualButton.layer.borderColor = nil
            self.weekPriceLabel.textColor = .white
            self.lifetimePriceLabel.textColor = .black
            self.annualButton.backgroundColor =  UIColor(white: 1.2, alpha: 0.5)
            self.setupIcon(button: self.weekButton, hidden: false)
        } completion: { _ in
//            self.setupIcon(button: self.annualButton, hidden: true)
        }
    }
    
    @objc func tapLifetimeButton() {
        annualButton.isSelected = true
        weekButton.isSelected = false
        
        UIView.animate(withDuration: 0.3) {
            self.annualButton.backgroundColor = .black
            self.annualButton.layer.borderColor = Colors.opacWhite.color.cgColor
            self.annualButton.layer.borderWidth = 2
            self.weekButton.layer.borderWidth = 0
            self.lifetimePriceLabel.textColor = .white
            self.weekPriceLabel.textColor = .black
            self.weekButton.backgroundColor =  UIColor(white: 1.2, alpha: 0.5)
            self.setupIcon(button: self.annualButton, hidden: false)
        } completion: { _ in
//            self.setupIcon(button: self.weekButton, hidden: true)
        }
    }
    
    @objc func tappedTermsOfServiceButton() {
        if let url = URL(string: Constants.Links.termsOfService.rawValue) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    @objc func tappedPrivacyPoliceButton() {
        if let url = URL(string: Constants.Links.privacyPolicy.rawValue) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    @objc func tappedRestorePurchasesButton() {
        viewModel.restorePurchases()
    }
}

extension PremiumVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return properties.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PremiumTableViewCell.identifier, for: indexPath) as! PremiumTableViewCell
        let model = properties[indexPath.row]
        cell.configure(with: model)
        cell.accessoryType = .none
        return cell
    }
    
    
    func addProperties() {
        properties.append(Property(
            icon: Images.infinity!,
            title: LocaleKeys.Premium.title1.rawValue.locale(),
            subtitle: LocaleKeys.Premium.premium1.rawValue.locale()))
        properties.append(Property(
            icon: Images.fork!,
            title: LocaleKeys.Premium.title2.rawValue.locale(),
            subtitle: LocaleKeys.Premium.premium2.rawValue.locale()))
        properties.append(Property(
            icon: Images.scribble!,
            title: LocaleKeys.Premium.title3.rawValue.locale(),
            subtitle: LocaleKeys.Premium.premium3.rawValue.locale()))
    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y != 0 {
            scrollView.contentOffset.y = 0
        }
    }
}


// MARK: DESIGN PREMİUM VİEW CONTROLLER
extension PremiumVC {
    func setupPremiumText() {
        view.addSubview(premiumText)
        
        premiumText.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            premiumText.topAnchor.constraint(equalTo:view.safeAreaLayoutGuide.topAnchor, constant: 25),
            premiumText.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        
    }
    
    func setupPremiumButtons() {
        let stack = UIStackView()
        view.addSubview(stack)
        
        stack.addArrangedSubview(termsOfServiceButton)
        stack.addArrangedSubview(restorePurchasesButton)
        stack.addArrangedSubview(privacyPolicyButton)
        stack.spacing = 20
        
        view.addSubview(stack)
        
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor,constant: -view.bounds.height * 0.02)
        ])
    }
    
    
    func createLayer() {
        let layer = CAEmitterLayer()
        layer.emitterPosition = CGPoint(x: view.center.x, y: 0)
        
        let cell = CAEmitterCell()
        
        let colors: [UIColor] = [
            .systemRed,
            .systemBlue,
            .systemOrange,
            .systemPink,
            .systemYellow,
            .systemMint,
            .systemPurple
        ]
        let size = CGSize(width: 50, height: 50)
        
        let image = Images.whiteImage?.resize(toSize: size)
        
        let cells: [CAEmitterCell] = colors.compactMap {
            let cell = CAEmitterCell()
            cell.scale = 0.05
            cell.birthRate = 50
            cell.emissionRange = .pi * 2
            cell.lifetime = 3
            cell.velocity = 150
            cell.color = $0.cgColor
            cell.contents = image?.cgImage
            return cell
        }
        
        layer.emitterCells =  cells
        
        view.layer.addSublayer(layer)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            layer.removeFromSuperlayer()
        }
    }
    
    
    func setupLatestExpirationDateLabel() {
        view.addSubview(latestExpirationDateLabel)
        
        latestExpirationDateLabel.isHidden = true
        
        latestExpirationDateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            latestExpirationDateLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor,constant: -view.bounds.height * 0.04),
            latestExpirationDateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            
            latestExpirationDateLabel.heightAnchor.constraint(equalToConstant: 100),
            latestExpirationDateLabel.widthAnchor.constraint(equalToConstant: view.bounds.width)
        ])
    }
    
    
    func setupBackgroundImage() {
        let backgroundImage = UIImageView(frame: UIScreen.main.bounds)
        backgroundImage.image = Images.background
        backgroundImage.contentMode = .scaleAspectFill
        
        let backgroundView = UIView(frame: view.frame)
        backgroundView.addSubview(backgroundImage)
        view.addSubview(backgroundView)
    }
    
    
    private func setupPremiumPhoto() {
        view.addSubview(premiumPhoto)
        premiumPhoto.image?.withRenderingMode(.alwaysOriginal)
        
        premiumPhoto.isHidden = true
        
        premiumPhoto.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            premiumPhoto.topAnchor.constraint(equalTo: view.topAnchor, constant: view.bounds.height * 0.1),
            premiumPhoto.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            premiumPhoto.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.35),
            premiumPhoto.widthAnchor.constraint(equalTo: premiumPhoto.heightAnchor)
        ])
    }
    
    
    private func setupPremiumLabel() {
        view.addSubview(premiumLabel)
      
        premiumLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            premiumLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            premiumLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor,constant: 50),
            
            premiumLabel.heightAnchor.constraint(equalToConstant: 100),
            premiumLabel.widthAnchor.constraint(equalToConstant: view.bounds.width)
        ])
    }
    
    
    private func setupPremiumSubheadlineLabel() {
        view.addSubview(premiumLabelSubheadline)
        
        premiumLabelSubheadline.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            premiumLabelSubheadline.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            premiumLabelSubheadline.centerYAnchor.constraint(equalTo: view.centerYAnchor,constant: 100),
            
            premiumLabelSubheadline.heightAnchor.constraint(equalToConstant: 150),
            premiumLabelSubheadline.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.9)
        ])
    }
    
    
    private func setupExitButton() {
        view.addSubview(exitButton)
        exitButton.addAction(closePage,for: .touchUpInside)
        
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            exitButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,constant: 20),
            exitButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,constant: 20),
            exitButton.heightAnchor.constraint(equalToConstant: 35),
            exitButton.widthAnchor.constraint(equalToConstant: 35)
        ])
    }
    
    
    private func setupContinueButton() {
        continueButton.addTarget(self, action: #selector(didTapSubscribe), for: .touchUpInside)
        
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            continueButton.bottomAnchor.constraint(equalTo: view.bottomAnchor,constant: -view.bounds.height * 0.09),
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            continueButton.heightAnchor.constraint(equalToConstant: 50),
            continueButton.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.85),
        ])
        
       
    }
    
    
    private func setupTable() {
        tableView.rowHeight = view.bounds.height * 0.10
        tableView.allowsSelection = false
        view.addSubview(tableView)
        tableView.layer.cornerRadius = 12
        tableView.backgroundColor = Colors.accent.color.withAlphaComponent(0.2)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableHeaderView = UIView(frame: CGRect(x: 15, y: 0, width: tableView.frame.width, height: 0.01))
        tableView.bounces = false
        tableView.contentSize = CGSize(width: tableView.frame.size.width, height: view.bounds.height * 0.3)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,constant: view.bounds.height * 0.1),
            tableView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            tableView.heightAnchor.constraint(equalToConstant: view.bounds.height * 0.3),
            tableView.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.85)
        ])
    }
    
    
    private func setupIndicator() {
        view.addSubview(progressViewContainer)
        progressViewContainer.addSubview(progressView)
        
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressViewContainer.translatesAutoresizingMaskIntoConstraints = false
        
        
        NSLayoutConstraint.activate([
            progressViewContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressViewContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            progressViewContainer.widthAnchor.constraint(equalToConstant: 100),
            progressViewContainer.heightAnchor.constraint(equalToConstant: 100),
        ])
        
        NSLayoutConstraint.activate([
            progressView.centerXAnchor.constraint(equalTo: progressViewContainer.centerXAnchor),
            progressView.centerYAnchor.constraint(equalTo: progressViewContainer.centerYAnchor)
        ])
    }
    
    private func setupButtons() {
        stackButton.addArrangedSubview(weekButton)
        stackButton.addArrangedSubview(annualButton)
        view.addSubview(stackButton)
        stackButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackButton.bottomAnchor.constraint(equalTo: view.bottomAnchor,constant: -view.bounds.height * 0.2),
            weekButton.heightAnchor.constraint(equalToConstant: 60),
            weekButton.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.85),
            annualButton.heightAnchor.constraint(equalToConstant: 60),
            annualButton.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.85)
        ])
        
        weekButton.addTarget(self, action: #selector(tapWeekButton), for: .touchUpInside)
        annualButton.addTarget(self, action: #selector(tapLifetimeButton), for: .touchUpInside)
    }
    
    private func setupIcon(button: UIButton,hidden:Bool) {
        checkIcon.isHidden = hidden
        button.addSubview(checkIcon)
        checkIcon.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            checkIcon.leadingAnchor.constraint(equalTo: button.leadingAnchor,constant: 5),
            checkIcon.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            checkIcon.heightAnchor.constraint(equalTo: button.heightAnchor, multiplier: 0.7), // Adjust the multiplier as needed
        ])
    }
    
    private func setupLifetimeIcon() {
        checkIcon.isHidden = true
        annualButton.addSubview(checkIcon)
        checkIcon.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            checkIcon.leadingAnchor.constraint(equalTo: annualButton.leadingAnchor,constant: 5),
            checkIcon.centerYAnchor.constraint(equalTo: annualButton.centerYAnchor),
        ])
    }
    
    private func setupWeekPriceLabel() {
        weekButton.addSubview(weekPriceLabel)
        weekPriceLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            weekPriceLabel.bottomAnchor.constraint(equalTo: weekPriceLabel.superview!.bottomAnchor, constant: -8), // Sağ alt köşeye yerleştirme
            weekPriceLabel.trailingAnchor.constraint(equalTo: weekPriceLabel.superview!.trailingAnchor, constant: -8)
        ])
    }
    
    private func setupLifetimePriceLabel() {
        annualButton.addSubview(lifetimePriceLabel)
        lifetimePriceLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lifetimePriceLabel.bottomAnchor.constraint(equalTo: lifetimePriceLabel.superview!.bottomAnchor, constant: -8),
            lifetimePriceLabel.trailingAnchor.constraint(equalTo: lifetimePriceLabel.superview!.trailingAnchor, constant: -8)
        ])
    }
}

extension PremiumVC: PremiumViewControllerDelegate {
    fileprivate func userPremium() {
        self.premiumLabel.isHidden = false
        self.premiumPhoto.isHidden = false
        self.premiumLabelSubheadline.isHidden = false
        self.latestExpirationDateLabel.isHidden = false
        self.tableView.isHidden = true
        self.continueButton.isHidden = true
        self.weekButton.isHidden = true
        self.annualButton.isHidden = true
        self.lifetimePriceLabel.isHidden = true
        self.weekPriceLabel.isHidden = true
    }
    
    
    fileprivate func userNotPremium() {
        self.premiumLabel.isHidden = true
        self.premiumPhoto.isHidden = true
        self.premiumLabelSubheadline.isHidden = true
        self.latestExpirationDateLabel.isHidden = true
        self.tableView.isHidden = false
        self.continueButton.isHidden = false
        self.weekButton.isHidden = false
        self.annualButton.isHidden = false
        self.lifetimePriceLabel.isHidden = false
        self.weekPriceLabel.isHidden = false
    }
    
    
    func handleViewModelOutput(_ output: PremiumViewModelOutput) {
        DispatchQueue.main.async{
            switch output {
            case .setLoading(let isLoading):
                switch isLoading {
                case true:
                    self.customLoadingView()
                    
                case false:
                    self.dismissLoadingView()
                }
                
            case .showAlert:
                let alert = showAlert(
                    title: LocaleKeys.Premium.restore.rawValue.locale(),
                    message: "",
                    buttonTitle: LocaleKeys.Settings.okButton.rawValue.locale(),
                    secondButtonTitle: LocaleKeys.Error.backButton.rawValue.locale(),
                    completionHandler:  {
                        Purchases.shared.restorePurchases()
                    })
                self.present(alert, animated:true)
                
            case .showError(let error):
                let alert = showAlert(title: LocaleKeys.Error.alert.rawValue.locale(),
                                      message: error.localizedDescription,
                                      buttonTitle: LocaleKeys.Error.okButton.rawValue.locale(), secondButtonTitle: nil)
                self.present(alert, animated:true)
                
            case .getUserInfo(let info):
                self.latestExpirationDateLabel.text = "\(LocaleKeys.Premium.latestExpirationDate.rawValue.locale()) \( String(describing: info.latestExpirationDate!.formatted()))"
                
            case.userIsPremium(let isPremium):
                if isPremium {
                    self.userPremium()
                    
                } else {
                    self.userNotPremium()
                }
                
            case .getOfferings(let offering):
                self.offering = offering
                if let weekOffering = offering.weekly {
                    self.weekPriceLabel.text = weekOffering.localizedPriceString
                }
                if let annual = offering.annual {
                    self.lifetimePriceLabel.text = annual.localizedPriceString
                }
                
            case .getAllOfferings(let package):
                self.packages = package
                self.weekPriceLabel.text = package[0].localizedPriceString
                self.lifetimePriceLabel.text = package[1].localizedPriceString
                
            case .userBecamePremium:
                self.createLayer()
                self.userPremium()
                
            }
        }
    }
}

