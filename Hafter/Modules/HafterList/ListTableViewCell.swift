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
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        v.layer.cornerRadius = DS.Radius.poster
        v.backgroundColor = UIColor.secondarySystemFill
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = DS.Typography.title2
        l.textColor = .label
        l.numberOfLines = 2
        return l
    }()

    private let yearLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = DS.Typography.callout
        l.textColor = .secondaryLabel
        return l
    }()

    private lazy var textStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [titleLabel, yearLabel])
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .vertical
        s.alignment = .leading
        s.spacing = DS.Spacing.xs / 2
        return s
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }

    func setup(movie: Movie, caption: String? = nil) {
        titleLabel.text = movie.title
        let year = movie.year()
        let text = [year, caption].compactMap { $0 }.filter { $0.isEmpty == false }.joined(separator: " · ")
        if text.isEmpty {
            yearLabel.text = nil
            yearLabel.isHidden = true
        } else {
            yearLabel.text = text
            yearLabel.isHidden = false
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        yearLabel.text = nil
        yearLabel.isHidden = false
        posterImageView.image = nil
    }

    private func setupLayout() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.addSubview(posterImageView)
        contentView.addSubview(textStack)

        NSLayoutConstraint.activate([
            posterImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DS.Spacing.m),
            posterImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: DS.Spacing.s),
            posterImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -DS.Spacing.s),
            posterImageView.widthAnchor.constraint(equalTo: posterImageView.heightAnchor, multiplier: 0.7),

            textStack.leadingAnchor.constraint(equalTo: posterImageView.trailingAnchor, constant: DS.Spacing.m),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DS.Spacing.m),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
}
