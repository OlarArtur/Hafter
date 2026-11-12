//
//  CustomSearchBar.swift
//  Hafter
//
//  Created by Artur Olar on 01.04.2022.
//

import UIKit

class CustomSearchBar: UISearchBar {

    private struct Constants {
        static let cornerRadius: CGFloat = 10
    }

    let placeholderWidth: CGFloat = 53

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupAppearance()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupAppearance()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupAppearance()
    }

    // MARK: Private

    private func setupAppearance() {
        searchBarStyle = .minimal
        backgroundImage = UIImage()
        backgroundColor = .clear
        tintColor = DS.Color.accent
        showsBookmarkButton = false
        showsCancelButton = false

        if #available(iOS 13.0, *) {
            styleSearchTextField(searchTextField)
        }
    }

    private func styleSearchTextField(_ textField: UITextField) {
        textField.backgroundColor = UIColor.secondarySystemGroupedBackground
        textField.layer.cornerRadius = Constants.cornerRadius
        textField.layer.borderWidth = 0
        textField.clipsToBounds = true
        textField.font = .systemFont(ofSize: 17)
        textField.defaultTextAttributes = [.foregroundColor: UIColor.label]

        let placeholderColor = UIColor.placeholderText
        textField.attributedPlaceholder = NSAttributedString(
            string: textField.placeholder ?? "",
            attributes: [.foregroundColor: placeholderColor]
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if #available(iOS 13.0, *) {
            styleSearchTextField(searchTextField)
        }
    }

    // MARK: Public
    func centerText() {
        layoutIfNeeded()
        let offset = UIOffset(horizontal: (bounds.size.width / 2) - placeholderWidth, vertical: 0)
        setPositionAdjustment(offset, for: .search)
    }

    var queryIsEmpty: Bool {
        text == nil || text == ""
    }
}
