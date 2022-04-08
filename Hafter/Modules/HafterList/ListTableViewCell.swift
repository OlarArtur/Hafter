//
//  ListTableViewCell.swift
//  Hafter
//
//  Created by Artur Olar on 08.04.2022.
//

import UIKit

final class ListTableViewCell: UITableViewCell {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet weak var posterImageView: UIImageView!
    
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
}
