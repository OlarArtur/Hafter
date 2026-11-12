//
//  AddTableViewCell.swift
//  Hafter
//
//  Created by Artur Olar on 02.04.2022.
//

import UIKit

final class AddTableViewCell: UITableViewCell {

    private let posterImageView: UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        v.layer.cornerRadius = 6
        v.backgroundColor = UIColor.secondarySystemFill
        v.tintColor = UIColor.tertiaryLabel
        v.image = UIImage(systemName: "film")
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.textColor = .label
        l.numberOfLines = 2
        return l
    }()

    private let yearLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 15, weight: .regular)
        l.textColor = .secondaryLabel
        return l
    }()

    private lazy var textStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [titleLabel, yearLabel])
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .vertical
        s.alignment = .leading
        s.spacing = 4
        return s
    }()

    private let detailButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(UIImage(named: "detail_icon"), for: .normal)
        b.tintColor = DS.Color.iconMuted
        return b
    }()

    private let addButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(UIImage(named: "add_plus"), for: .normal)
        b.tintColor = DS.Color.iconAdd
        return b
    }()

    private var infoAction: (() -> Void)?
    var addAction: (() -> Void)?

    private var imageRequestToken = UUID()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }

    func setup(movie: Movie, imageLoader: ImageLoaderProtocol, infoAction: @escaping () -> Void) {
        titleLabel.text = movie.title
        if let year = movie.year() {
            yearLabel.text = year
            yearLabel.isHidden = false
        } else {
            yearLabel.text = nil
            yearLabel.isHidden = true
        }
        self.infoAction = infoAction

        let token = UUID()
        imageRequestToken = token
        posterImageView.image = UIImage(systemName: "film")
        posterImageView.tintColor = .tertiaryLabel

        if let url = movie.posterThumbnailURL() {
            imageLoader.imageFromUrl(url: url) { [weak self] image in
                guard let self, self.imageRequestToken == token else { return }
                self.posterImageView.tintColor = nil
                self.posterImageView.transition(to: image)
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageRequestToken = UUID()
        titleLabel.text = nil
        yearLabel.text = nil
        posterImageView.image = UIImage(systemName: "film")
        posterImageView.tintColor = .tertiaryLabel
    }

    private func setupLayout() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .secondarySystemGroupedBackground

        contentView.addSubview(posterImageView)
        contentView.addSubview(textStack)
        contentView.addSubview(detailButton)
        contentView.addSubview(addButton)

        detailButton.addTarget(self, action: #selector(detailAction), for: .touchUpInside)
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)

        let posterWidth: CGFloat = 48
        let posterHeight: CGFloat = 72

        NSLayoutConstraint.activate([
            posterImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            posterImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            posterImageView.widthAnchor.constraint(equalToConstant: posterWidth),
            posterImageView.heightAnchor.constraint(equalToConstant: posterHeight),

            textStack.leadingAnchor.constraint(equalTo: posterImageView.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: detailButton.leadingAnchor, constant: -8),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            detailButton.widthAnchor.constraint(equalToConstant: 40),
            detailButton.heightAnchor.constraint(equalToConstant: 40),
            detailButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            detailButton.trailingAnchor.constraint(equalTo: addButton.leadingAnchor, constant: -4),

            addButton.widthAnchor.constraint(equalToConstant: 40),
            addButton.heightAnchor.constraint(equalToConstant: 40),
            addButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            addButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
        ])
    }

    @objc private func detailAction() {
        infoAction?()
    }

    @objc private func addButtonTapped() {
        addAction?()
    }
}
