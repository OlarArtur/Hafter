//
//  ItemDetailViewController.swift
//  Hafter
//
//  Created by Artur Olar on 16.11.2023.
//

import Foundation

import UIKit

final class ItemDetailViewController: BaseViewController<ItemDetailViewModelProtocol>, CustomAlertRouterProtocol {
    
    @IBOutlet private weak var posterImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var genresLabel: UILabel!
    @IBOutlet private weak var budgetLabel: UILabel!
    @IBOutlet private weak var overviewLabel: UILabel!
    
    private var reuseIdentifier = "GenresCollectionViewCell"
    
    @IBOutlet private weak var genresCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupGenresCollectionView()
    }
    
    @IBAction private func closeAction(_ sender: UIButton) {
        hide(animated: true)
    }
}

private extension ItemDetailViewController {
    
    func setupUI() {
        viewModel?.getPoster(completion: { [weak self] image in
            self?.posterImageView.image = image
        })
        titleLabel.text = viewModel?.title
        overviewLabel.text = viewModel?.overview
        
        budgetLabel.text = viewModel?.budget
        
        view.backgroundColor = viewModel?.color
    }
    
    func setupGenresCollectionView() {
        genresCollectionView.dataSource = self
        genresCollectionView.registerNibCell(GenresCollectionViewCell.self)
        genresCollectionView.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }
}

extension ItemDetailViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.genres.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? GenresCollectionViewCell, let viewModel else {
            return UICollectionViewCell()
        }
        cell.setup(title: viewModel.genres[indexPath.row])
        return cell
    }
}
