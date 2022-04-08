//
//  ListTableViewDelegate.swift
//  Hafter
//
//  Created by Artur Olar on 08.04.2022.
//

import UIKit

class ListTableViewDelegate: NSObject {
    
    private var viewModel: ListViewModelProtocol
    
    init(viewModel: ListViewModelProtocol) {
        self.viewModel = viewModel
    }
}

extension ListTableViewDelegate: UITableViewDelegate {
    
}
