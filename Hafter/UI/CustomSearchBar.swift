//
//  CustomSearchBar.swift
//  Hafter
//
//  Created by Artur Olar on 01.04.2022.
//

import UIKit

class CustomSearchBar: UISearchBar {
    
    private struct Constants {
        static let cornerRadius: CGFloat = 5.0
        static let borderWidth: CGFloat = 1.0
    }
    
    let placeholderWidth: CGFloat = 53
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupAppearance()
    }
    
    // MARK: Private
    
    private func setupAppearance() {
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [.foregroundColor: UIColor(red: 119 / 255.0, green: 128 / 255.0, blue: 135 / 255.0, alpha: 1.0)]
        backgroundImage = UIImage()
        backgroundColor = .white
        borderColor = UIColor(red: 211 / 255.0, green: 211 / 255.0, blue: 211 / 255.0, alpha: 1.0)
        
        for subView in subviews {
            subView.backgroundColor = .white
            for subView1 in subView.subviews {
                if let textField = subView1 as? UITextField {
                    textField.backgroundColor = UIColor.white
                    textField.layer.borderWidth = Constants.borderWidth
                    textField.layer.cornerRadius = Constants.cornerRadius
                    textField.layer.borderColor = UIColor(red: 211 / 255.0, green: 211 / 255.0, blue: 211 / 255.0, alpha: 1.0).cgColor
                    
                    // customize placeholder color
                    let textFieldInsideUISearchBarLabel = textField.value(forKey: "placeholderLabel") as? UILabel
                    textFieldInsideUISearchBarLabel?.textColor = UIColor(red: 142 / 255.0, green: 142 / 255.0, blue: 147 / 255.0, alpha: 1.0)
                }
            }
        }
    }
    
    // MARK: Public
    func centerText() {
        layoutIfNeeded()
        let offset = UIOffset(horizontal: (bounds.size.width / 2) - placeholderWidth, vertical: 0)
        setPositionAdjustment(offset, for: .search)
    }
    
    var queryIsEmpty: Bool {
        return text == nil || text == ""
    }
}
