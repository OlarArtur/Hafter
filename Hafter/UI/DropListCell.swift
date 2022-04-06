//
//  DropListCell.swift
//  Hafter
//
//  Created by Artur Olar on 03.04.2022.
//

import UIKit

class DropListCell: UITableViewCell {
    
    let dropListImageView: UIImageView = {
        let arrowView = UIImageView()
        arrowView.contentMode = .scaleAspectFit
        return arrowView
    }()
    
    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    // MARK: Public
    func configure(image: UIImage) {
        dropListImageView.image = image
    }
    
    func setupView() {
        selectionStyle = .none
        contentView.addSubview(dropListImageView)
        setupConstraints()
    }
    
    func setupConstraints() {
        dropListImageView.translatesAutoresizingMaskIntoConstraints = false
        dropListImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        dropListImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        dropListImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -3).isActive = true
        dropListImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 3).isActive = true
    }
}
