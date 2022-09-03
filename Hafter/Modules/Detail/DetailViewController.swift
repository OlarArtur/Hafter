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
    
    @IBOutlet private weak var posterImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var overviewLabel: UILabel!
    @IBOutlet private weak var popularityLabel: UILabel!
    @IBOutlet private weak var genresLabel: UILabel!
    @IBOutlet private weak var budgetLabel: UILabel!
    @IBOutlet private weak var dateReleaseLabel: UILabel!
    
    private let imageLoader = ImageLoader()
    
    deinit {
        print("deinit DetailViewController")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let viewModel = viewModel else { return }
        let movie = viewModel.getMovie()
        titleLabel.text = movie.title
        overviewLabel.text = movie.overview
        popularityLabel.text = "\(movie.popularity)"
        genresLabel.text = movie.genres.map { $0.name }.joined(separator: ", ")
        budgetLabel.text = NumberFormatter.localizedString(from: NSNumber(value: movie.budget), number: .decimal)
        
        if let date = movie.releaseDate {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year], from: date)
            if let year = components.year {
                dateReleaseLabel.text = "\(year)"
            }
        }
        
        if let posterURL = movie.posterImageURL() {
            imageLoader.imageFromUrl(url: posterURL) { [weak self] image in
                self?.posterImageView.transition(to: image)
            }
        } else {
            posterImageView.transition(to: UIImage.image(named: ImageConstants.posterholder))
        }
    }
}

private extension DetailViewController {
    
}

extension DetailViewController: DetailViewProtocol {
    
}
