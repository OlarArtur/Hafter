//
//  ItemDetailViewController.swift
//  Hafter
//
//  Created by Artur Olar on 16.11.2023.
//

import UIKit

final class ItemDetailViewController: BaseViewController<ItemDetailViewModelProtocol>, CustomAlertRouterProtocol {

    private let posterImageView: UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        v.layer.cornerRadius = 20
        v.image = UIImage(named: ImageConstants.posterholder)
        return v
    }()

    private let closeButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(UIImage(named: "close"), for: .normal)
        return b
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .boldSystemFont(ofSize: 20)
        l.numberOfLines = 0
        return l
    }()

    private let genresCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.scrollDirection = .horizontal
        let c = UICollectionView(frame: .zero, collectionViewLayout: layout)
        c.translatesAutoresizingMaskIntoConstraints = false
        c.backgroundColor = .systemBackground
        c.showsHorizontalScrollIndicator = false
        return c
    }()

    private let budgetLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 15)
        return l
    }()

    private let budgetIcon: UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.contentMode = .scaleAspectFit
        v.image = UIImage(named: "money")
        return v
    }()

    private let overviewLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.numberOfLines = 0
        return l
    }()

    private let detailContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 40
        return v
    }()

    private let reuseIdentifier = "GenresCollectionViewCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        closeButton.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        setupUI()
        setupGenresCollectionView()
    }

    @objc private func closeAction() {
        hide(animated: true)
    }
}

private extension ItemDetailViewController {

    func setupLayout() {
        view.addSubview(detailContainer)
        view.addSubview(posterImageView)
        view.addSubview(closeButton)
        detailContainer.addSubview(titleLabel)
        detailContainer.addSubview(genresCollectionView)
        detailContainer.addSubview(budgetIcon)
        detailContainer.addSubview(budgetLabel)
        detailContainer.addSubview(overviewLabel)

        NSLayoutConstraint.activate([
            posterImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            posterImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            posterImageView.widthAnchor.constraint(equalTo: posterImageView.heightAnchor, multiplier: 0.65),
            posterImageView.bottomAnchor.constraint(lessThanOrEqualTo: detailContainer.topAnchor, constant: 60),

            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 19),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),

            detailContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            detailContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            detailContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            detailContainer.topAnchor.constraint(equalTo: posterImageView.bottomAnchor, constant: -40),

            titleLabel.topAnchor.constraint(equalTo: detailContainer.topAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: detailContainer.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: detailContainer.trailingAnchor, constant: -20),

            genresCollectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            genresCollectionView.leadingAnchor.constraint(equalTo: detailContainer.leadingAnchor),
            genresCollectionView.trailingAnchor.constraint(equalTo: detailContainer.trailingAnchor),
            genresCollectionView.heightAnchor.constraint(equalToConstant: 22),

            budgetIcon.leadingAnchor.constraint(equalTo: detailContainer.leadingAnchor, constant: 20),
            budgetIcon.topAnchor.constraint(equalTo: genresCollectionView.bottomAnchor, constant: 10),
            budgetIcon.widthAnchor.constraint(equalToConstant: 16),
            budgetIcon.heightAnchor.constraint(equalToConstant: 16),

            budgetLabel.leadingAnchor.constraint(equalTo: budgetIcon.trailingAnchor, constant: 4),
            budgetLabel.centerYAnchor.constraint(equalTo: budgetIcon.centerYAnchor),
            budgetLabel.trailingAnchor.constraint(lessThanOrEqualTo: detailContainer.trailingAnchor, constant: -20),

            overviewLabel.topAnchor.constraint(equalTo: budgetLabel.bottomAnchor, constant: 30),
            overviewLabel.leadingAnchor.constraint(equalTo: detailContainer.leadingAnchor, constant: 20),
            overviewLabel.trailingAnchor.constraint(equalTo: detailContainer.trailingAnchor, constant: -20),
            overviewLabel.bottomAnchor.constraint(lessThanOrEqualTo: detailContainer.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

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
        genresCollectionView.registerCell(GenresCollectionViewCell.self)
        genresCollectionView.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }
}

extension ItemDetailViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.genres.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? GenresCollectionViewCell,
              let viewModel = viewModel else {
            return UICollectionViewCell()
        }
        cell.setup(title: viewModel.genres[indexPath.row])
        return cell
    }
}
