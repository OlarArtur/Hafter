//
//  HereafterCollectionViewCell.swift
//  Hafter
//
//  Created by Artur Olar on 05.10.2022.
//

import UIKit

class HereafterCollectionViewCell : UICollectionViewCell {
    
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        posterImageView.image = nil
        titleLabel.text = nil
    }
    
    func setup(title: String) {
        titleLabel.text = title
    }
}
