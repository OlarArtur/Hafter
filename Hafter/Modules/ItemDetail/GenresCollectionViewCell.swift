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
        l.font = .systemFont(ofSize: 14)
        l.textColor = UIColor(red: 0.36, green: 0.33, blue: 0.54, alpha: 1)
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
        contentView.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 4
        contentView.layer.borderColor = UIColor(red: 0.36, green: 0.33, blue: 0.54, alpha: 1).cgColor
        contentView.layer.borderWidth = 1
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2)
        ])
    }
}
