//
//  DetailViewController.swift
//  Hafter
//
//  Created by Artur Olar on 03.09.2022.
//

import UIKit

protocol DetailViewProtocol: AnyObject {
}

final class DetailViewController: BaseViewController<DetailViewModelProtocol> {

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let posterImageView = UIImageView()
    private let overviewLabel = UILabel()
    private let popularityLabel = UILabel()
    private let genresLabel = UILabel()
    private let budgetLabel = UILabel()
    private let dateReleaseLabel = UILabel()
    private let closeButton = UIButton(type: .system)

    private let imageLoader = ImageLoader()

    deinit {
        print("deinit DetailViewController")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
        closeButton.setImage(UIImage(named: "close"), for: .normal)
        closeButton.addTarget(self, action: #selector(closeAction), for: .touchUpInside)

        guard let viewModel = viewModel else { return }
        let movie = viewModel.getMovie()
        titleLabel.text = movie.title
        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        overviewLabel.text = movie.overview
        overviewLabel.font = .systemFont(ofSize: 17, weight: .medium)
        overviewLabel.numberOfLines = 0

        popularityLabel.text = "\(movie.popularity)"
        genresLabel.text = movie.genres.map { $0.name }.joined(separator: ", ")
        budgetLabel.text = NumberFormatter.localizedString(from: NSNumber(value: movie.budget), number: .decimal)
        if let date = movie.releaseDate {
            let year = Calendar.current.component(.year, from: date)
            dateReleaseLabel.text = "\(year)"
        }

        if let posterURL = movie.posterImageURL() {
            imageLoader.imageFromUrl(url: posterURL) { [weak self] image in
                self?.posterImageView.transition(to: image)
            }
        } else {
            posterImageView.transition(to: UIImage.image(named: ImageConstants.posterholder))
        }
    }

    @objc private func closeAction() {
        hide(animated: true)
    }
}

private extension DetailViewController {

    func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        posterImageView.translatesAutoresizingMaskIntoConstraints = false
        overviewLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        posterImageView.contentMode = .scaleAspectFill
        posterImageView.clipsToBounds = true

        view.addSubview(scrollView)
        view.addSubview(closeButton)
        scrollView.addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(posterImageView)
        contentView.addSubview(overviewLabel)

        let infoStack = makeInfoStack()
        contentView.addSubview(infoStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 50),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),

            posterImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            posterImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            posterImageView.widthAnchor.constraint(equalToConstant: 156),
            posterImageView.heightAnchor.constraint(equalTo: posterImageView.widthAnchor, multiplier: 12/9),

            overviewLabel.topAnchor.constraint(equalTo: posterImageView.bottomAnchor, constant: 40),
            overviewLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            overviewLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),

            infoStack.topAnchor.constraint(equalTo: overviewLabel.bottomAnchor, constant: 40),
            infoStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            infoStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            infoStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -50)
        ])
    }

    func makeInfoStack() -> UIStackView {
        let rows = [
            row(title: "Popularity:", valueLabel: popularityLabel),
            row(title: "Genres:", valueLabel: genresLabel),
            row(title: "Budget:", valueLabel: budgetLabel),
            row(title: "Date release:", valueLabel: dateReleaseLabel)
        ]
        popularityLabel.font = .systemFont(ofSize: 16, weight: .medium)
        genresLabel.font = .systemFont(ofSize: 16)
        budgetLabel.font = .systemFont(ofSize: 16)
        dateReleaseLabel.font = .systemFont(ofSize: 16)
        let stack = UIStackView(arrangedSubviews: rows)
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    func row(title: String, valueLabel: UILabel) -> UIView {
        let container = UIView()
        let titleL = UILabel()
        titleL.text = title
        titleL.font = .systemFont(ofSize: 16)
        valueLabel.numberOfLines = 0
        container.addSubview(titleL)
        container.addSubview(valueLabel)
        titleL.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleL.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            titleL.topAnchor.constraint(equalTo: container.topAnchor),
            titleL.widthAnchor.constraint(equalToConstant: 100),
            valueLabel.leadingAnchor.constraint(equalTo: titleL.trailingAnchor, constant: 10),
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            valueLabel.topAnchor.constraint(equalTo: container.topAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
        return container
    }
}

extension DetailViewController: DetailViewProtocol {
}
