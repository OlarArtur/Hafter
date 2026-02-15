//
//  RandomizeViewController.swift
//  Hafter
//
//  Created by Artur Olar on 09.04.2022.
//

import UIKit

final class RandomizeViewController: BaseViewController<RandomizeViewModelProtocol> {

    private let contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemBackground
        return v
    }()

    private let closeButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(UIImage(named: "close"), for: .normal)
        return b
    }()

    private let posterImageView: UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.contentMode = .scaleAspectFit
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 17)
        l.numberOfLines = 0
        return l
    }()

    private let originalTitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 17)
        l.numberOfLines = 0
        return l
    }()

    private let popularityTitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Popularity:"
        l.font = .systemFont(ofSize: 17)
        return l
    }()

    private let popularityLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 17)
        return l
    }()

    private let overviewTextView: UITextView = {
        let t = UITextView()
        t.translatesAutoresizingMaskIntoConstraints = false
        t.isEditable = false
        t.font = .systemFont(ofSize: 14)
        t.backgroundColor = .systemBackground
        return t
    }()

    private let bookmarkAllView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        return v
    }()

    private let bookmarkFormostView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = ColorConstants.formost
        return v
    }()

    private let bookmarkPossiblyView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = ColorConstants.possibly
        return v
    }()

    private let bookmarkIfNothElseView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = ColorConstants.ifNothingElse
        return v
    }()

    private let allLabel: UILabel = {
        let l = UILabel()
        l.text = "All"
        l.font = .systemFont(ofSize: 15)
        l.textAlignment = .center
        return l
    }()

    private let foremostLabel: UILabel = {
        let l = UILabel()
        l.text = "Formost"
        l.font = .systemFont(ofSize: 15)
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private let possiblyLabel: UILabel = {
        let l = UILabel()
        l.text = "Possibly"
        l.font = .systemFont(ofSize: 15)
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private let ifNothingElseLabel: UILabel = {
        let l = UILabel()
        l.text = "If nothing else"
        l.font = .systemFont(ofSize: 15)
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        setupLayout()

        closeButton.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(closeAction))
        swipeGesture.direction = .down
        view.addGestureRecognizer(swipeGesture)

        bookmarkAllView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(bookmarkAllAction)))
        bookmarkFormostView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(bookmarkFormostAction)))
        bookmarkPossiblyView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(bookmarkPossiblyAction)))
        bookmarkIfNothElseView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(bookmarkINEAction)))

        contentView.layer.shadowOffset = CGSize(width: 0, height: 3)

        guard let movie = viewModel?.getMovie() else {
            clean()
            return
        }
        feel(movie: movie)
        feelPoster()
        bindViewModel()
    }

    private func setupLayout() {
        view.addSubview(contentView)
        contentView.addSubview(closeButton)
        contentView.addSubview(posterImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(originalTitleLabel)
        contentView.addSubview(popularityTitleLabel)
        contentView.addSubview(popularityLabel)
        contentView.addSubview(overviewTextView)
        contentView.addSubview(bookmarkAllView)
        contentView.addSubview(bookmarkFormostView)
        contentView.addSubview(bookmarkPossiblyView)
        contentView.addSubview(bookmarkIfNothElseView)
        [allLabel, foremostLabel, possiblyLabel, ifNothingElseLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        bookmarkAllView.addSubview(allLabel)
        bookmarkFormostView.addSubview(foremostLabel)
        bookmarkPossiblyView.addSubview(possiblyLabel)
        bookmarkIfNothElseView.addSubview(ifNothingElseLabel)

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 40),
            contentView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -40),
            contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),

            closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            closeButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
            closeButton.widthAnchor.constraint(equalToConstant: 20),
            closeButton.heightAnchor.constraint(equalToConstant: 20),

            posterImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            posterImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            posterImageView.widthAnchor.constraint(equalToConstant: 100),
            posterImageView.heightAnchor.constraint(equalToConstant: 195),

            titleLabel.leadingAnchor.constraint(equalTo: posterImageView.trailingAnchor, constant: 15),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 50),

            originalTitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            originalTitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            originalTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),

            popularityTitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            popularityTitleLabel.topAnchor.constraint(equalTo: originalTitleLabel.bottomAnchor, constant: 10),

            popularityLabel.leadingAnchor.constraint(equalTo: popularityTitleLabel.trailingAnchor, constant: 10),
            popularityLabel.centerYAnchor.constraint(equalTo: popularityTitleLabel.centerYAnchor),

            overviewTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            overviewTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            overviewTextView.topAnchor.constraint(equalTo: posterImageView.bottomAnchor, constant: 10),
            overviewTextView.bottomAnchor.constraint(equalTo: bookmarkAllView.topAnchor, constant: -10),

            bookmarkAllView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bookmarkAllView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bookmarkAllView.heightAnchor.constraint(equalToConstant: 60),
            bookmarkAllView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.25),

            bookmarkFormostView.leadingAnchor.constraint(equalTo: bookmarkAllView.trailingAnchor),
            bookmarkFormostView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bookmarkFormostView.widthAnchor.constraint(equalTo: bookmarkAllView.widthAnchor),
            bookmarkFormostView.heightAnchor.constraint(equalTo: bookmarkAllView.heightAnchor),

            bookmarkPossiblyView.leadingAnchor.constraint(equalTo: bookmarkFormostView.trailingAnchor),
            bookmarkPossiblyView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bookmarkPossiblyView.widthAnchor.constraint(equalTo: bookmarkAllView.widthAnchor),
            bookmarkPossiblyView.heightAnchor.constraint(equalTo: bookmarkAllView.heightAnchor),

            bookmarkIfNothElseView.leadingAnchor.constraint(equalTo: bookmarkPossiblyView.trailingAnchor),
            bookmarkIfNothElseView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bookmarkIfNothElseView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bookmarkIfNothElseView.heightAnchor.constraint(equalTo: bookmarkAllView.heightAnchor),

            allLabel.centerXAnchor.constraint(equalTo: bookmarkAllView.centerXAnchor),
            allLabel.centerYAnchor.constraint(equalTo: bookmarkAllView.centerYAnchor),
            
            foremostLabel.centerYAnchor.constraint(equalTo: bookmarkFormostView.centerYAnchor),
            foremostLabel.leadingAnchor.constraint(equalTo: bookmarkFormostView.leadingAnchor),
            foremostLabel.trailingAnchor.constraint(equalTo: bookmarkFormostView.trailingAnchor),
            
            possiblyLabel.centerYAnchor.constraint(equalTo: bookmarkPossiblyView.centerYAnchor),
            possiblyLabel.leadingAnchor.constraint(equalTo: bookmarkPossiblyView.leadingAnchor),
            possiblyLabel.trailingAnchor.constraint(equalTo: bookmarkPossiblyView.trailingAnchor),
            
            ifNothingElseLabel.centerYAnchor.constraint(equalTo: bookmarkIfNothElseView.centerYAnchor),
            ifNothingElseLabel.leadingAnchor.constraint(equalTo: bookmarkIfNothElseView.leadingAnchor),
            ifNothingElseLabel.trailingAnchor.constraint(equalTo: bookmarkIfNothElseView.trailingAnchor)
        ])
    }

    @objc private func closeAction() {
        dismiss(animated: true)
    }

    @objc private func bookmarkAllAction() {
        bookmarkAllView.backgroundColor = .white
        bookmarkFormostView.backgroundColor = ColorConstants.formost
        bookmarkPossiblyView.backgroundColor = ColorConstants.possibly
        bookmarkIfNothElseView.backgroundColor = ColorConstants.ifNothingElse
        viewModel?.switchTo(type: nil)
    }

    @objc private func bookmarkFormostAction() {
        bookmarkAllView.backgroundColor = .gray
        bookmarkFormostView.backgroundColor = .white
        bookmarkPossiblyView.backgroundColor = ColorConstants.possibly
        bookmarkIfNothElseView.backgroundColor = ColorConstants.ifNothingElse
        viewModel?.switchTo(type: .foremost)
    }

    @objc private func bookmarkPossiblyAction() {
        bookmarkAllView.backgroundColor = .gray
        bookmarkFormostView.backgroundColor = ColorConstants.formost
        bookmarkPossiblyView.backgroundColor = .white
        bookmarkIfNothElseView.backgroundColor = ColorConstants.ifNothingElse
        viewModel?.switchTo(type: .possibly)
    }

    @objc private func bookmarkINEAction() {
        bookmarkAllView.backgroundColor = .gray
        bookmarkFormostView.backgroundColor = ColorConstants.formost
        bookmarkPossiblyView.backgroundColor = ColorConstants.possibly
        bookmarkIfNothElseView.backgroundColor = .white
        viewModel?.switchTo(type: .ifNothingElse)
    }
}

private extension RandomizeViewController {

    func bindViewModel() {
        viewModel?.reload = { [weak self] in
            guard let movie = self?.viewModel?.getMovie() else {
                self?.clean()
                return
            }
            self?.feel(movie: movie)
            self?.feelPoster()
        }
    }

    func feelPoster() {
        viewModel?.getPoster { [weak self] image in
            self?.posterImageView.transition(to: image)
        }
    }

    func feel(movie: Movie) {
        popularityTitleLabel.isHidden = false
        var title = movie.title
        if let date = movie.releaseDate {
            let year = Calendar.current.component(.year, from: date)
            title.append(" (\(year))")
        }
        titleLabel.text = title
        originalTitleLabel.text = movie.originalTitle
        overviewTextView.text = movie.overview
        popularityLabel.text = "\(movie.popularity)"
    }

    func clean() {
        titleLabel.text = nil
        originalTitleLabel.text = nil
        overviewTextView.text = nil
        popularityLabel.text = nil
        posterImageView.image = nil
        popularityTitleLabel.isHidden = true
    }
}

extension RandomizeViewController: UIViewControllerTransitioningDelegate {

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentAnimator()
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimator()
    }
}
