//
//  RandomizeViewController.swift
//  Hafter
//
//  Created by Artur Olar on 09.04.2022.
//

import UIKit

final class RandomizeViewController: BaseViewController<RandomizeViewModelProtocol> {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var originalTitleLabel: UILabel!
    @IBOutlet private weak var posterImageView: UIImageView!
    @IBOutlet private weak var overviewTextView: UITextView!
    @IBOutlet private weak var popularityLabel: UILabel!
    @IBOutlet private weak var popularityTitleLabel: UILabel!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var contentView: UIView!
    
    @IBOutlet private weak var bookmarkAllView: UIView!
    @IBOutlet private weak var bookmarkFormostView: UIView!
    @IBOutlet private weak var bookmarkPossiblyView: UIView!
    @IBOutlet private weak var bookmarkIfNothElseView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let movie = viewModel?.getMovie() else {
            clean()
            return
        }
        feel(movie: movie)
        feelPoster()
        
        bindViewModel()
        
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(closeAction(_:)))
        swipeGesture.direction = .down
        view.addGestureRecognizer(swipeGesture)
        
        let allGesture = UITapGestureRecognizer(target: self, action: #selector(bookmarkAllAction))
        bookmarkAllView.addGestureRecognizer(allGesture)
        let foremostGesture = UITapGestureRecognizer(target: self, action: #selector(bookmarkFormostAction))
        bookmarkFormostView.addGestureRecognizer(foremostGesture)
        let possiblyGesture = UITapGestureRecognizer(target: self, action: #selector(bookmarkPossiblyAction))
        bookmarkPossiblyView.addGestureRecognizer(possiblyGesture)
        let ifeGesture = UITapGestureRecognizer(target: self, action: #selector(bookmarkINEAction))
        bookmarkIfNothElseView.addGestureRecognizer(ifeGesture)
        
        contentView.layer.shadowOffset = CGSize(width: 0, height: 3)
    }
    
    @IBAction private func closeAction(_ sender: UIButton) {
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
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year], from: date)
            if let year = components.year {
                title.append("(\(year))")
            }
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
