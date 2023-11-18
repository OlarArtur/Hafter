//
//  GenresCollectionViewCell.swift
//  Hafter
//
//  Created by Artur Olar on 17.11.2023.
//

import UIKit

class GenresCollectionViewCell : UICollectionViewCell {
    
    @IBOutlet private weak var titleLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
    }
    
    func setup(title: String) {
        titleLabel.text = title
    }
}
