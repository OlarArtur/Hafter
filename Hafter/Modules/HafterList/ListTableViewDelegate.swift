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
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        var actions: [UIContextualAction] = []
        for type in viewModel.swipeLeftTypes() {
            let action = UIContextualAction(style: .normal,
                                            title: type.title) { [weak self] (action, view, completionHandler) in
                self?.viewModel.updateType(index: indexPath.row, type: type)
                completionHandler(true)
            }
            action.backgroundColor = type.typeColor
            actions.append(action)
        }
        return UISwipeActionsConfiguration(actions: actions)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        var actions: [UIContextualAction] = []
        for type in viewModel.swipeRightTypes() {
            let action = UIContextualAction(style: .normal,
                                            title: type.title) { [weak self] (action, view, completionHandler) in
                self?.viewModel.updateType(index: indexPath.row, type: type)
                completionHandler(true)
            }
            action.backgroundColor = type.typeColor
            actions.append(action)
        }
        return UISwipeActionsConfiguration(actions: actions)
    }
}
