//
//  GenresCollectionViewCell.swift
//  Hafter
//
//  Created by Artur Olar on 17.11.2023.
//

import UIKit

final class GenresCollectionViewCell: UICollectionViewCell {

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = DS.Typography.footnote
        l.textColor = DS.Color.accent
        l.textAlignment = .center
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
    }

    func setup(title: String) {
        titleLabel.text = title
    }

    private func setupLayout() {
        contentView.backgroundColor = DS.Color.accentDim
        contentView.layer.cornerRadius = DS.Radius.small
        contentView.clipsToBounds = true
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DS.Spacing.xs),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DS.Spacing.xs),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 3),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -3)
        ])
    }
}
