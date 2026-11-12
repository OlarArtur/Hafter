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

enum ViewedDetailsEditor {
    static func present(on controller: UIViewController, completion: @escaping (Int, Date) -> Void) {
        let alert = UIAlertController(
            title: "Watched",
            message: "Rate it from 1 to 5. The date is today unless you type YYYY-MM-DD.",
            preferredStyle: .alert
        )
        alert.addTextField { field in
            field.placeholder = "Rating"
            field.keyboardType = .numberPad
            field.text = "5"
        }
        alert.addTextField { field in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            field.placeholder = "YYYY-MM-DD"
            field.text = formatter.string(from: Date())
        }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            let rating = ViewedShelf.clampRating(Int(alert.textFields?.first?.text ?? "") ?? 5)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let date = formatter.date(from: alert.textFields?.last?.text ?? "") ?? Date()
            completion(rating, date)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        controller.present(alert, animated: true)
    }
}
