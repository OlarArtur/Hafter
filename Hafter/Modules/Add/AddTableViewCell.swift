//
//  AddTableViewCell.swift
//  Hafter
//
//  Created by Artur Olar on 02.04.2022.
//

import UIKit

final class AddTableViewCell: UITableViewCell {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var detailButton: UIButton!
    @IBOutlet private weak var selectedImageView: UIImageView!
    
    private var infoAction: (() -> Void)?
    
    override var isSelected: Bool {
        get {
            return super.isSelected
        }
        set {
            detailButton.isHidden = !isSelected
            selectedImageView.isHidden = !isSelected
            super.isSelected = newValue
        }
        
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
    
    @IBAction private func detailAction(_ sender: UIButton) {
        infoAction?()
    }
}
