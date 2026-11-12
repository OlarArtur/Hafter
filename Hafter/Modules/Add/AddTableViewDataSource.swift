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
    private let imageLoader: ImageLoaderProtocol

    init(viewModel: AddViewModelProtocol, imageLoader: ImageLoaderProtocol, addAction: @escaping (() -> Void)) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
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
        let movie = viewModel.movieAt(index: indexPath.row)
        cell.setup(movie: movie, imageLoader: imageLoader) { [weak self] in
            self?.viewModel.detailsFor(index: indexPath.row)
        }
        cell.addAction = { [weak self] in
            self?.viewModel.select(index: indexPath.row)
            self?.addAction()
        }
        return cell
    }
}
