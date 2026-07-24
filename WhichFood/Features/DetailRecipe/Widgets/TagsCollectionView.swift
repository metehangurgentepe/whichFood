//
//  TagsCollectionView.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 1.03.2025.
//

import Foundation
import UIKit

class TagsCollectionView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private var tags: [String] = []
    private var collectionView: UICollectionView!
    private var heightConstraint: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCollectionView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCollectionView()
    }
    
    private func setupCollectionView() {
        let layout = TagsFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 8 // Space between tags horizontally
        layout.minimumLineSpacing = 8 // Space between rows
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(TagCell.self, forCellWithReuseIdentifier: "TagCell")
        
        // Important: Disable scrolling to allow wrapping
        collectionView.isScrollEnabled = false
        
        addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func createFlowLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        return layout
    }
    
    func configure(with tags: [String]) {
        self.tags = tags
        collectionView.reloadData()
        
        DispatchQueue.main.async {
            self.updateHeight()
        }
    }
    
    private func updateHeight() {
        // Wait for the next layout pass to get the correct content size
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let contentHeight = self.collectionView.collectionViewLayout.collectionViewContentSize.height
            let minHeight: CGFloat = 36 // Height for a single row
            
            // Remove existing constraint
            if let constraint = self.heightConstraint {
                constraint.isActive = false
            }
            
            self.heightConstraint = self.heightAnchor.constraint(equalToConstant: max(contentHeight, minHeight))
            self.heightConstraint?.isActive = true
            
            // Force layout update
            self.superview?.layoutIfNeeded()
        }
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TagCell", for: indexPath) as! TagCell
        cell.configure(with: tags[indexPath.item])
        return cell
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return calculateSizeForText(tags[indexPath.item])
    }
    
    private func calculateSizeForText(_ text: String) -> CGSize {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.text = text
        label.sizeToFit()
        
        // Increase horizontal padding
        let horizontalPadding: CGFloat = 40 // Increased from 35
        let width = label.frame.width + horizontalPadding
        
        return CGSize(width: width, height: 36)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if !tags.isEmpty {
            updateHeight()
        }
    }
}

class TagCell: UICollectionViewCell {
    private let tagLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = UIColor(red: 1.0, green: 0.9, blue: 0.88, alpha: 1.0)
        layer.cornerRadius = 18
        clipsToBounds = true
        
        // Configure label
        tagLabel.font = UIFont.systemFont(ofSize: 16)
        tagLabel.textColor = UIColor(red: 0.9, green: 0.4, blue: 0.2, alpha: 1.0) // Reddish-orange color
        tagLabel.textAlignment = .center
        
        contentView.addSubview(tagLabel)
        tagLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tagLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            tagLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12), // Reduced padding
            tagLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12) // Reduced padding
        ])
    }
    
    func configure(with tag: String) {
        tagLabel.text = tag
    }
}


// First, create a new custom flow layout class
class TagsFlowLayout: UICollectionViewFlowLayout {
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        // Get the original layout attributes from parent class
        guard let originalAttributes = super.layoutAttributesForElements(in: rect)?.map({ $0.copy() as! UICollectionViewLayoutAttributes }) else {
            return nil
        }
        
        // Calculate available width
        let collectionViewWidth = collectionView?.frame.width ?? 0
        let availableWidth = collectionViewWidth - (sectionInset.left + sectionInset.right)
        
        // Keep track of the current row's Y position
        var yOffset: CGFloat = sectionInset.top
        var xOffset: CGFloat = sectionInset.left
        var rowHeight: CGFloat = 0
        
        // Sort attributes by y position then by x position
        let sortedAttributes = originalAttributes.sorted {
            if $0.frame.origin.y != $1.frame.origin.y {
                return $0.frame.origin.y < $1.frame.origin.y
            }
            return $0.frame.origin.x < $1.frame.origin.x
        }
        
        // Process attributes by row
        var currentRowAttributes: [UICollectionViewLayoutAttributes] = []
        
        for attributes in sortedAttributes {
            // If this is a new row
            if attributes.frame.origin.y >= yOffset + rowHeight {
                // Process the previous row
                xOffset = sectionInset.left
                if !currentRowAttributes.isEmpty {
                    yOffset += rowHeight + minimumLineSpacing
                }
                currentRowAttributes = []
                rowHeight = 0
            }
            
            // Determine if this item fits in the current row
            let width = attributes.frame.width
            if xOffset + width > availableWidth && xOffset > sectionInset.left {
                // Item doesn't fit, move to next row
                xOffset = sectionInset.left
                yOffset += rowHeight + minimumLineSpacing
                rowHeight = 0
            }
            
            // Position the item
            var newFrame = attributes.frame
            newFrame.origin.x = xOffset
            newFrame.origin.y = yOffset
            attributes.frame = newFrame
            
            // Update tracking variables
            xOffset += width + minimumInteritemSpacing
            rowHeight = max(rowHeight, attributes.frame.height)
            currentRowAttributes.append(attributes)
        }
        
        return originalAttributes
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        // Always invalidate layout when bounds change to recalculate positions
        return true
    }
}
