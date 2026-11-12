//
//  AddTableViewDelegate.swift
//  Hafter
//
//  Created by Artur Olar on 02.04.2022.
//

import UIKit

class AddTableViewDelegate: NSObject {
    
    private var viewModel: AddViewModelProtocol
    
    init(viewModel: AddViewModelProtocol) {
        self.viewModel = viewModel
    }
}

extension AddTableViewDelegate: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        100
    }
}
