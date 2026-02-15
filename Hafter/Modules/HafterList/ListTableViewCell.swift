//
//  ListTableViewCell.swift
//  Hafter
//
//  Created by Artur Olar on 08.04.2022.
//

import UIKit

final class ListTableViewCell: UITableViewCell {

    let posterImageView: UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.contentMode = .scaleAspectFit
        v.clipsToBounds = true
        v.layer.cornerRadius = 8
        return v
    }()

    private let titleContainerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(red: 0.51, green: 0.58, blue: 0.99, alpha: 0.26)
        v.layer.cornerRadius = 10
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = .black
        l.backgroundColor = .clear
        l.numberOfLines = 0
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        titleLabel.text = nil
        posterImageView.image = nil
    }

    func setup(title: String) {
        titleLabel.text = title
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        posterImageView.image = nil
    }

    private func setupLayout() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.addSubview(posterImageView)
        contentView.addSubview(titleContainerView)
        titleContainerView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            posterImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 25),
            posterImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            posterImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            posterImageView.widthAnchor.constraint(equalTo: posterImageView.heightAnchor, multiplier: 0.7),

            titleContainerView.leadingAnchor.constraint(equalTo: posterImageView.trailingAnchor, constant: -10),
            titleContainerView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            titleLabel.leadingAnchor.constraint(equalTo: titleContainerView.leadingAnchor, constant: 28),
            titleLabel.trailingAnchor.constraint(equalTo: titleContainerView.trailingAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: titleContainerView.topAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: titleContainerView.bottomAnchor, constant: -8)
        ])
    }
}
