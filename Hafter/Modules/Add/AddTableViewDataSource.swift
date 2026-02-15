//
//  AddTableViewDataSource.swift
//  Hafter
//
//  Created by Artur Olar on 02.04.2022.
//

import UIKit

class AddTableViewDataSource: NSObject {
    
    private var viewModel: AddViewModelProtocol
    private var addAction: (() -> Void)
    
    init(viewModel: AddViewModelProtocol, addAction: @escaping (() -> Void)) {
        self.viewModel = viewModel
        self.addAction = addAction
    }
}

extension AddTableViewDataSource: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItems()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AddTableViewCell", for: indexPath) as? AddTableViewCell else {
            return UITableViewCell()
        }
        cell.setup(title: viewModel.itemFor(index: indexPath.row)) { [weak self] in
            self?.viewModel.detailsFor(index: indexPath.row)
        }
        cell.addAction = { [weak self] in
            self?.viewModel.select(index: indexPath.row)
            self?.addAction()
        }
        return cell
    }
}
