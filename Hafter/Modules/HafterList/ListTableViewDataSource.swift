//
//  ListTableViewDataSource.swift
//  Hafter
//
//  Created by Artur Olar on 08.04.2022.
//

import UIKit

class ListTableViewDataSource: NSObject {
    
    private let viewModel: ListViewModelProtocol
    private let imageLoader: ImageLoaderProtocol
    
    init(viewModel: ListViewModelProtocol, imageLoader: ImageLoaderProtocol) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
    }
}

extension ListTableViewDataSource: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItems()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ListTableViewCell", for: indexPath) as? ListTableViewCell else {
            return UITableViewCell()
        }
        cell.tag = indexPath.row
        let movie = viewModel.itemFor(index: indexPath.row)
        if let posterURL = movie.posterImageURL() {
            imageLoader.imageFromUrl(url: posterURL) { image in
                if (cell.tag == indexPath.row) {
                    cell.posterImageView.transition(to: image)
                }
            }
        } else {
            if (cell.tag == indexPath.row) {
                cell.posterImageView.transition(to: UIImage.image(named: ImageConstants.posterholder))
            }
        }
        cell.setup(title: movie.title)
        return cell
    }
}
