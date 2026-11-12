//
//  SessionResultViewController.swift
//  Hafter
//

import UIKit

final class SessionResultViewController: UIViewController {

    var session: MovieSession?
    var uid: String?
    var localService: LocalServiceProtocol?

    private let imageLoader = ImageLoader()

    // MARK: - Views

    private let gradientLayer: CAGradientLayer = {
        let g = CAGradientLayer()
        g.colors = [DS.Color.accent.cgColor, DS.Color.brandIndigo.cgColor]
        g.startPoint = CGPoint(x: 0, y: 0)
        g.endPoint = CGPoint(x: 1, y: 1)
        return g
    }()

    private let headerLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = DS.Typography.display
        l.textColor = .white
        l.text = "Tonight's pick"
        l.textAlignment = .center
        l.adjustsFontSizeToFitWidth = true
        return l
    }()

    private let posterImageView: UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        v.layer.cornerRadius = DS.Radius.card
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.35
        v.layer.shadowRadius = 20
        v.layer.shadowOffset = CGSize(width: 0, height: 10)
        v.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = DS.Typography.title1
        l.textColor = .white
        l.numberOfLines = 2
        l.textAlignment = .center
        return l
    }()

    private let yearLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = DS.Typography.callout
        l.textColor = UIColor.white.withAlphaComponent(0.7)
        l.textAlignment = .center
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = DS.Typography.caption
        l.textColor = UIColor.white.withAlphaComponent(0.6)
        l.textAlignment = .center
        return l
    }()

    private lazy var watchedButton: UIButton = {
        var c = UIButton.Configuration.filled()
        c.title = "Mark as watched"
        c.baseBackgroundColor = .white
        c.baseForegroundColor = DS.Color.brandIndigo
        c.cornerStyle = .medium
        let b = UIButton(configuration: c)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(watchedTapped), for: .touchUpInside)
        return b
    }()

    private lazy var doneButton: UIButton = {
        var c = UIButton.Configuration.filled()
        c.title = "Done"
        c.baseBackgroundColor = UIColor.white.withAlphaComponent(0.2)
        c.baseForegroundColor = .white
        c.cornerStyle = .medium
        let b = UIButton(configuration: c)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        return b
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        configure()
        if let session, let localService {
            TonightSync.remember(session: session, local: localService)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }
}

// MARK: - Setup

private extension SessionResultViewController {

    func setupLayout() {
        view.layer.insertSublayer(gradientLayer, at: 0)
        view.addSubview(headerLabel)
        view.addSubview(posterImageView)
        view.addSubview(titleLabel)
        view.addSubview(yearLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(watchedButton)
        view.addSubview(doneButton)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: DS.Spacing.l),
            headerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            posterImageView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: DS.Spacing.l),
            posterImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            posterImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            posterImageView.heightAnchor.constraint(equalTo: posterImageView.widthAnchor, multiplier: 1.5),

            titleLabel.topAnchor.constraint(equalTo: posterImageView.bottomAnchor, constant: DS.Spacing.l),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DS.Spacing.m),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DS.Spacing.m),

            yearLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: DS.Spacing.xs / 2),
            yearLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: yearLabel.bottomAnchor, constant: DS.Spacing.m),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            watchedButton.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -DS.Spacing.xs),
            watchedButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DS.Spacing.m),
            watchedButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DS.Spacing.m),
            watchedButton.heightAnchor.constraint(equalToConstant: 50),

            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -DS.Spacing.l),
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DS.Spacing.m),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DS.Spacing.m),
            doneButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    func configure() {
        guard let session else { return }
        switch session.mode {
        case .swipe:
            let count = session.matchingMovies().count
            subtitleLabel.text = count == 1 ? "You both said yes!" : "From \(count) matches — picked for you"
        case .vote:
            subtitleLabel.text = "The votes are in!"
        case .random:
            subtitleLabel.text = "Selected at random"
        }

        guard let resultID = session.result,
              let movie = session.movies.first(where: { $0.id == resultID }) else {
            titleLabel.text = "No match found"
            subtitleLabel.text = "Try again with more movies"
            return
        }

        titleLabel.text = movie.title
        yearLabel.text = movie.year ?? ""

        if let url = movie.posterThumbnailURL {
            imageLoader.imageFromUrl(url: url) { [weak self] image in
                DispatchQueue.main.async { self?.posterImageView.image = image }
            }
        }
    }

    @objc func watchedTapped() {
        guard let session, let localService else { return }
        TonightSync.markWatched(session: session, uid: uid, local: localService)
        watchedButton.isEnabled = false
        var config = watchedButton.configuration
        config?.title = "Moved to Viewed"
        watchedButton.configuration = config
    }

    @objc func doneTapped() {
        dismiss(animated: true)
    }
}
