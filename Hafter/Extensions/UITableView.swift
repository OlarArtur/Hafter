//
//  UITableView.swift
//  Hafter
//
//  Created by Artur Olar on 02.04.2022.
//

import UIKit

extension UITableView {

    func registerNibCell<T: UITableViewCell>(_ cell: T.Type) {
        let nib = UINib(nibName: String(describing: cell), bundle: nil)
        register(nib, forCellReuseIdentifier: String(describing: cell))
    }

    func registerCell<T: UITableViewCell>(_ cell: T.Type) {
        register(cell, forCellReuseIdentifier: String(describing: cell))
    }
}

extension UICollectionView {

    func registerNibCell<T: UICollectionViewCell>(_ cell: T.Type) {
        let nib = UINib(nibName: String(describing: cell), bundle: nil)
        register(nib, forCellWithReuseIdentifier: String(describing: cell))
    }

    func registerCell<T: UICollectionViewCell>(_ cell: T.Type) {
        register(cell, forCellWithReuseIdentifier: String(describing: cell))
    }
}
