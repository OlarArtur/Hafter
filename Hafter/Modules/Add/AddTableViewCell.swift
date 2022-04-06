//
//  AddTableViewCell.swift
//  Hafter
//
//  Created by Artur Olar on 02.04.2022.
//

import UIKit

final class AddTableViewCell: UITableViewCell {
    
    @IBOutlet private weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.text = nil
    }
    
    func setup(title: String) {
        titleLabel.text = title
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
    }
}
