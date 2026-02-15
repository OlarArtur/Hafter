//
//  AddTableViewCell.swift
//  Hafter
//
//  Created by Artur Olar on 02.04.2022.
//

import UIKit

final class AddTableViewCell: UITableViewCell {

    private let selectedImageView: UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        v.image = UIImage(named: "linear-background")
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 17)
        return l
    }()

    private let detailButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(UIImage(named: "detail_icon"), for: .normal)
        return b
    }()

    private let addButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(UIImage(named: "add_plus"), for: .normal)
        b.tintColor = UIColor(red: 0.188, green: 0.69, blue: 0.78, alpha: 1)
        return b
    }()

    private var infoAction: (() -> Void)?
    var addAction: (() -> Void)?

    override var isSelected: Bool {
        get { super.isSelected }
        set {
            detailButton.isHidden = !newValue
            addButton.isHidden = !newValue
            selectedImageView.isHidden = !newValue
            super.isSelected = newValue
        }
    }

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
        titleLabel.text = nil
        detailButton.isHidden = !isSelected
        selectedImageView.isHidden = !isSelected
    }

    func setup(title: String, infoAction: @escaping () -> Void) {
        titleLabel.text = title
        self.infoAction = infoAction
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
    }

    private func setupLayout() {
        selectionStyle = .none
        contentView.addSubview(selectedImageView)
        contentView.addSubview(detailButton)
        contentView.addSubview(titleLabel)
        contentView.addSubview(addButton)

        detailButton.addTarget(self, action: #selector(detailAction), for: .touchUpInside)
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            selectedImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: -10),
            selectedImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            selectedImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            selectedImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            detailButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            detailButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            detailButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            detailButton.widthAnchor.constraint(equalTo: detailButton.heightAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: detailButton.trailingAnchor, constant: 10),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: addButton.leadingAnchor, constant: -8),

            addButton.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),
            addButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            addButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            addButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            addButton.widthAnchor.constraint(equalTo: addButton.heightAnchor)
        ])
    }

    @objc private func detailAction() {
        infoAction?()
    }

    @objc private func addButtonTapped() {
        addAction?()
    }
}
