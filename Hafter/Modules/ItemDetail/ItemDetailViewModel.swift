//
//  ItemDetailViewModel.swift
//  Hafter
//
//  Created by Artur Olar on 16.11.2023.
//

import UIKit

protocol ItemDetailViewModelProtocol {
    var title: String { get }
    var overview: String { get }
    var budget: String { get }
    var genres: [String] { get }
    var color: UIColor { get }
    var tags: [String] { get }
    var onTagsUpdated: (() -> Void)? { get set }
    func getPoster(completion: @escaping (UIImage?) -> Void)
    func addTag(_ name: String)
    func removeTag(at index: Int)
}

final class ItemDetailViewModel<Router: ItemDetailRouterProtocol>: BaseViewModel<Router> {

    private let localDataService: LocalServiceProtocol
    private let movie: DetailedMovie
    private let type: HereafterMovieType
    private let imageLoader = ImageLoader()

    private var _tags: [String] = []
    var onTagsUpdated: (() -> Void)?

    init(movie: DetailedMovie, type: HereafterMovieType, router: Router, localDataService: LocalServiceProtocol) {
        self.movie = movie
        self.type = type
        self.localDataService = localDataService
        super.init(router: router)
        _tags = localDataService.getTags(movieId: movie.id)
    }

    private func persistTags() {
        localDataService.updateTags(movieId: movie.id, tags: _tags) { [weak self] _ in
            DispatchQueue.main.async { self?.onTagsUpdated?() }
        }
    }
}

extension ItemDetailViewModel: ItemDetailViewModelProtocol {

    var color: UIColor { type.typeColor }

    var title: String {
        guard let year = movie.year() else { return movie.originalTitle }
        return movie.originalTitle + " (\(year))"
    }

    var overview: String { movie.overview }

    var budget: String {
        NumberFormatter.localizedString(from: NSNumber(value: movie.budget), number: .decimal)
    }

    var genres: [String] { movie.genres.map { $0.name } }

    var tags: [String] { _tags }

    func getPoster(completion: @escaping (UIImage?) -> Void) {
        if let posterURL = movie.posterOriginalImageURL() {
            imageLoader.imageFromUrl(url: posterURL) { image in completion(image) }
        } else {
            completion(nil)
        }
    }

    func addTag(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty, !_tags.contains(trimmed) else { return }
        _tags.append(trimmed)
        persistTags()
    }

    func removeTag(at index: Int) {
        guard index < _tags.count else { return }
        _tags.remove(at: index)
        persistTags()
    }
}
