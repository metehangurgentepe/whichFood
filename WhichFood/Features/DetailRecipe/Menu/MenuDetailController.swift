//
//  MenuController.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 18.09.2024.
//

import Foundation
import UIKit

protocol MenuDetailControllerDelegate: AnyObject {
    func didTapMenuItem(indexPath: IndexPath)
}

class MenuDetailController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    fileprivate var menuItems = [
        LocaleKeys.DetailRecipe.ingredients.rawValue.locale(),
        LocaleKeys.DetailRecipe.recipe.rawValue.locale()
        ]
    
    var menuBar: UIView = {
        let v = UIView()
        v.backgroundColor = .systemPink
        return v
    }()
    
    var delegate: MenuDetailControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.backgroundColor = Colors.accent.color
        collectionView.register(MenuCellDetail.self, forCellWithReuseIdentifier: MenuCellDetail.identifier)
        
        if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 0
            layout.minimumInteritemSpacing = 0
        }
        
        view.addSubview(menuBar)
        
        view.bringSubviewToFront(menuBar)
        
        menuBar.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(5)
            make.width.equalTo(ScreenSize.width / 3)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didTapMenuItem(indexPath: indexPath)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MenuCell", for: indexPath) as! MenuCell
        cell.label.text = menuItems[indexPath.item]
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = view.frame.width
        return .init(width: width/3, height: view.frame.height)
    }
}
