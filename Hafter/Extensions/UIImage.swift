//
//  UIImage.swift
//  Hafter
//
//  Created by Artur Olar on 31.03.2022.
//

import UIKit

extension UIImage {
    
    class func image(named: String) -> UIImage? {
        return UIImage(named: named, in: nil, compatibleWith: nil)
    }
}
