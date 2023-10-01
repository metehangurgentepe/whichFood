//
//  SelectCategoryVC.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 19.09.2023.
//

import UIKit

class SelectCategoryVC: UIViewController {
    var buttons : [UIButton] = []
    let nextButton = UIButton()
    let progressView = UIProgressView()
    let progressLabel = UILabel()
    var titles : [Category] = [
        Category(title:"Sağlıklı" , isSelected: false),
        Category(title:"Kolay" , isSelected: false),
        Category(title:"Orta" , isSelected: false),
        Category(title:"Zor" , isSelected: false),
        Category(title:"Keyifli" , isSelected: false),
        Category(title:"Doyurucu" , isSelected: false),
        Category(title:"Hızlı" , isSelected: false),
        Category(title:"Glutensiz" , isSelected: false),
        Category(title:"Vegan" , isSelected: false),
        Category(title:"Vejeteryan" , isSelected: false),
        ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setButtonTitles()
        setupNextButton()
        setupProgressView()
        setupLabel()
    }
    
    func setupProgressView() {
        view.addSubview(progressView)
        progressView.progressTintColor = .blue
        progressView.setProgress(0.5, animated: true)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.topAnchor,constant: view.bounds.height * 0.12),
            progressView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 10),
            progressView.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.9)
        ])
    }
    
    func setupLabel() {
        view.addSubview(progressLabel)
        progressLabel.text = "1/2"
        progressLabel.font = .preferredFont(forTextStyle: .headline)
        
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            progressLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: view.bounds.height * 0.14),
            progressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    func setButtonTitles() {
        var stackViews: [UIStackView] = []
       // var buttons: [UIButton] = []
        
        for title in titles {
            let button = CapsuleButton()
            button.setTitle(title.title, for: .normal)
            button.setTitleColor(.black, for: .normal)
            button.backgroundColor = Colors.secondAccent.color.withAlphaComponent(0.3)
            button.contentEdgeInsets = UIEdgeInsets(
                top: 10,
                left: 20,
                bottom: 10,
                right: 20)
            self.buttons.append(button)
            button.addTarget(self, action: #selector(changeStateButton), for: .touchUpInside)
        }
        
        // Düğmeleri üçerli gruplara bölelim
        for chunk in buttons.chunked(into: 3) { // Bu işlem için bir extension kullanıyoruz
            let stackView = UIStackView(arrangedSubviews: chunk)
            stackView.axis = .horizontal // Yatay yığın oluşturun
            stackView.spacing = 20 // Düğmeler arasındaki boşluk
            stackView.alignment = .center // Düğmeleri yatayda ortala
            stackViews.append(stackView)
        }
        
        // Yatay yığınlara dikey yığın ekleyin
        let verticalStackView = UIStackView(arrangedSubviews: stackViews)
        verticalStackView.axis = .vertical // Dikey yığın oluşturun
        verticalStackView.spacing = 10 // Yatay yığınlar arasındaki boşluk
        verticalStackView.alignment = .leading // Yatay yığınları soldan hizala
        
        view.addSubview(verticalStackView)
        
        // Dikey yığını görünümün ortasına yerleştirin
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            verticalStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            verticalStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,constant: 30)
        ])
    }
    
    func setupNextButton() {
        nextButton.setTitle("Next", for: .normal)
        nextButton.backgroundColor = Colors.primary.color
        view.addSubview(nextButton)
        nextButton.layer.cornerRadius = 12
        
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        
        nextButton.addTarget(self, action: #selector(nextButtonClicked), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            nextButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor,constant: -view.bounds.height * 0.06),
            nextButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            
            nextButton.widthAnchor.constraint(equalToConstant: view.bounds.width * 0.8),
            nextButton.heightAnchor.constraint(equalToConstant: view.bounds.height * 0.07)
        ])
    }
    
    @objc func nextButtonClicked() {
        let vc = SelectFoodViewController()
        let show = ShowFoodVC()
        let selected = buttons.filter({ $0.isSelected == true })
        vc.categories = selected.map{$0.currentTitle ?? ""}
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func changeStateButton(button: UIButton) {
        button.isSelected = !button.isSelected
        switch button.isSelected {
        case true:
            button.backgroundColor = Colors.secondAccent.color
        case false:
            button.backgroundColor = Colors.secondAccent.color.withAlphaComponent(0.3)
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, self.count)])
        }
    }
}

class CapsuleButton: UIButton {
  override func layoutSubviews() {
    super.layoutSubviews()
    let height = bounds.height
    layer.cornerRadius = height/2
  }
}

