//
//  EmptyStateView.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 27.02.2024.
//

import Foundation
import UIKit
import Lottie

class EmptyStateView: UIView {
    let titleLabel = TitleLabel(textAlignment: .center, fontSize: 24)
    let subtitleLabel = UILabel()
    let animationView = LottieAnimationView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience init(title: String, subtitle: String) {
        self.init(frame: .zero)
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }

    convenience init(message: String) {
        self.init(frame: .zero)
        titleLabel.text = message
        subtitleLabel.isHidden = true
    }

    private func configure() {
        backgroundColor = .systemBackground
        configureAnimationView()
        configureTitleLabel()
        configureSubtitleLabel()
    }

    private func configureAnimationView() {
        addSubview(animationView)

        animationView.animation = LottieAnimation.named("feature_1")
        animationView.loopMode = .loop
        animationView.contentMode = .scaleAspectFit
        animationView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            animationView.centerXAnchor.constraint(equalTo: centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -80),
            animationView.widthAnchor.constraint(equalToConstant: 120),
            animationView.heightAnchor.constraint(equalToConstant: 120)
        ])

        animationView.play()
    }

    private func configureTitleLabel() {
        addSubview(titleLabel)

        titleLabel.numberOfLines = 2
        titleLabel.textColor = .label
        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: animationView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
        ])
    }

    private func configureSubtitleLabel() {
        addSubview(subtitleLabel)

        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
        ])
    }
}
