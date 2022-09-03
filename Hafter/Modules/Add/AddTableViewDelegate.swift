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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        (tableView.cellForRow(at: indexPath) as? AddTableViewCell)?.isSelected = true
        viewModel.select(index: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        (tableView.cellForRow(at: indexPath) as? AddTableViewCell)?.isSelected = false
    }
}
