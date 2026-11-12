//
//  SwipeSessionViewController.swift
//  Hafter
//

import UIKit
import FirebaseFirestore

final class SwipeSessionViewController: UIViewController {

    var session: MovieSession?
    var uid: String?
    var onFinished: ((MovieSession) -> Void)?

    private let firestoreService: FirestoreServiceProtocol = FirestoreService.shared
    private let imageLoader = ImageLoader()

    private var movies: [SessionMovie] = []
    private var currentIndex = 0
    private var sessionListener: ListenerRegistration?

    // MARK: - Views

    private let progressLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = DS.Typography.caption
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        return l
    }()

    private let cardStack: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let yesLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "YES"
        l.font = DS.Typography.title1
        l.textColor = .systemGreen
        l.alpha = 0
        l.layer.borderWidth = 3
        l.layer.borderColor = UIColor.systemGreen.cgColor
        l.layer.cornerRadius = DS.Radius.chip
        l.clipsToBounds = true
        l.textAlignment = .center
        return l
    }()

    private let noLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "NOPE"
        l.font = DS.Typography.title1
        l.textColor = .systemRed
        l.alpha = 0
        l.layer.borderWidth = 3
        l.layer.borderColor = UIColor.systemRed.cgColor
        l.layer.cornerRadius = DS.Radius.chip
        l.clipsToBounds = true
        l.textAlignment = .center
        return l
    }()

    private lazy var yesButton: UIButton = {
        var c = UIButton.Configuration.filled()
        c.image = UIImage(systemName: "heart.fill")
        c.baseBackgroundColor = .systemGreen
        c.baseForegroundColor = .white
        c.cornerStyle = .capsule
        let b = UIButton(configuration: c)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(yesTapped), for: .touchUpInside)
        return b
    }()

    private lazy var noButton: UIButton = {
        var c = UIButton.Configuration.filled()
        c.image = UIImage(systemName: "xmark")
        c.baseBackgroundColor = .systemRed
        c.baseForegroundColor = .white
        c.cornerStyle = .capsule
        let b = UIButton(configuration: c)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(noTapped), for: .touchUpInside)
        return b
    }()

    private let waitingView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemGroupedBackground
        v.isHidden = true
        return v
    }()

    private let waitingLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = DS.Typography.title2
        l.textColor = DS.Color.labelMuted
        l.text = "Waiting for your friend..."
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private let waitingSpinner: UIActivityIndicatorView = {
        let a = UIActivityIndicatorView(style: .large)
        a.translatesAutoresizingMaskIntoConstraints = false
        a.color = DS.Color.accent
        return a
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Swipe"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(closeTapped)
        )
        setupLayout()
        loadMovies()
        startListening()
    }

    deinit { sessionListener?.remove() }
}

// MARK: - Setup

private extension SwipeSessionViewController {

    func setupLayout() {
        view.addSubview(progressLabel)
        view.addSubview(cardStack)
        view.addSubview(yesButton)
        view.addSubview(noButton)
        view.addSubview(waitingView)
        waitingView.addSubview(waitingLabel)
        waitingView.addSubview(waitingSpinner)

        NSLayoutConstraint.activate([
            progressLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: DS.Spacing.m),
            progressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            cardStack.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: DS.Spacing.m),
            cardStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DS.Spacing.m),
            cardStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DS.Spacing.m),
            cardStack.bottomAnchor.constraint(equalTo: yesButton.topAnchor, constant: -DS.Spacing.l),

            noButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DS.Spacing.xl),
            noButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -DS.Spacing.l),
            noButton.widthAnchor.constraint(equalToConstant: 64),
            noButton.heightAnchor.constraint(equalToConstant: 64),

            yesButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DS.Spacing.xl),
            yesButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -DS.Spacing.l),
            yesButton.widthAnchor.constraint(equalToConstant: 64),
            yesButton.heightAnchor.constraint(equalToConstant: 64),

            waitingView.topAnchor.constraint(equalTo: view.topAnchor),
            waitingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            waitingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            waitingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            waitingLabel.centerXAnchor.constraint(equalTo: waitingView.centerXAnchor),
            waitingLabel.centerYAnchor.constraint(equalTo: waitingView.centerYAnchor, constant: -DS.Spacing.m),
            waitingLabel.leadingAnchor.constraint(equalTo: waitingView.leadingAnchor, constant: DS.Spacing.xl),
            waitingLabel.trailingAnchor.constraint(equalTo: waitingView.trailingAnchor, constant: -DS.Spacing.xl),

            waitingSpinner.topAnchor.constraint(equalTo: waitingLabel.bottomAnchor, constant: DS.Spacing.m),
            waitingSpinner.centerXAnchor.constraint(equalTo: waitingView.centerXAnchor)
        ])
    }

    func loadMovies() {
        guard let session, let uid else { return }
        movies = session.movies
        let alreadyVoted = session.votesForUser(uid)
        let remaining = movies.filter { alreadyVoted[$0.id] == nil }
        currentIndex = movies.count - remaining.count
        showNextCard()
    }

    func showNextCard() {
        cardStack.subviews.forEach { $0.removeFromSuperview() }
        guard currentIndex < movies.count else {
            showWaiting()
            return
        }
        updateProgress()

        let movie = movies[currentIndex]
        let card = makeCard(for: movie)
        cardStack.addSubview(card)
        card.addSubview(yesLabel)
        card.addSubview(noLabel)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: cardStack.topAnchor),
            card.leadingAnchor.constraint(equalTo: cardStack.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: cardStack.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: cardStack.bottomAnchor),

            yesLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: DS.Spacing.l),
            yesLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: DS.Spacing.m),
            yesLabel.widthAnchor.constraint(equalToConstant: 80),
            yesLabel.heightAnchor.constraint(equalToConstant: 36),

            noLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: DS.Spacing.l),
            noLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -DS.Spacing.m),
            noLabel.widthAnchor.constraint(equalToConstant: 80),
            noLabel.heightAnchor.constraint(equalToConstant: 36)
        ])

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        card.addGestureRecognizer(pan)
    }

    func makeCard(for movie: SessionMovie) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = DS.Radius.card
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.12
        card.layer.shadowRadius = 12
        card.layer.shadowOffset = CGSize(width: 0, height: 4)

        let poster = UIImageView()
        poster.translatesAutoresizingMaskIntoConstraints = false
        poster.contentMode = .scaleAspectFill
        poster.clipsToBounds = true
        poster.layer.cornerRadius = DS.Radius.card
        poster.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        poster.backgroundColor = .systemGroupedBackground
        poster.image = UIImage(named: ImageConstants.posterholder)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = DS.Typography.title2
        titleLabel.numberOfLines = 2
        titleLabel.text = movie.title

        let yearLabel = UILabel()
        yearLabel.translatesAutoresizingMaskIntoConstraints = false
        yearLabel.font = DS.Typography.callout
        yearLabel.textColor = .secondaryLabel
        yearLabel.text = movie.year ?? ""

        card.addSubview(poster)
        card.addSubview(titleLabel)
        card.addSubview(yearLabel)

        NSLayoutConstraint.activate([
            poster.topAnchor.constraint(equalTo: card.topAnchor),
            poster.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            poster.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            poster.heightAnchor.constraint(equalTo: card.heightAnchor, multiplier: 0.75),

            titleLabel.topAnchor.constraint(equalTo: poster.bottomAnchor, constant: DS.Spacing.s),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: DS.Spacing.m),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -DS.Spacing.m),

            yearLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            yearLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: DS.Spacing.m)
        ])

        if let url = movie.posterThumbnailURL {
            imageLoader.imageFromUrl(url: url) { image in
                DispatchQueue.main.async { poster.image = image }
            }
        }

        return card
    }

    func updateProgress() {
        let total = movies.count
        let current = min(currentIndex + 1, total)
        progressLabel.text = "\(current) / \(total)"
    }

    func showWaiting() {
        waitingView.isHidden = false
        waitingSpinner.startAnimating()
        yesButton.isHidden = true
        noButton.isHidden = true
        progressLabel.isHidden = true
    }

    // MARK: - Gestures & actions

    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        guard let card = recognizer.view else { return }
        let translation = recognizer.translation(in: view)
        let rotation = translation.x / view.bounds.width * 0.3

        switch recognizer.state {
        case .changed:
            card.transform = CGAffineTransform(translationX: translation.x, y: translation.y / 3)
                .rotated(by: rotation)
            let progress = min(abs(translation.x) / (view.bounds.width * 0.4), 1.0)
            yesLabel.alpha = translation.x > 0 ? progress : 0
            noLabel.alpha = translation.x < 0 ? progress : 0

        case .ended, .cancelled:
            let threshold = view.bounds.width * 0.4
            if translation.x > threshold {
                animateCard(card, direction: 1) { [weak self] in self?.vote("yes") }
            } else if translation.x < -threshold {
                animateCard(card, direction: -1) { [weak self] in self?.vote("no") }
            } else {
                UIView.animate(withDuration: 0.3) {
                    card.transform = .identity
                    self.yesLabel.alpha = 0
                    self.noLabel.alpha = 0
                }
            }
        default: break
        }
    }

    func animateCard(_ card: UIView, direction: CGFloat, completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.3, animations: {
            card.transform = CGAffineTransform(translationX: direction * self.view.bounds.width * 1.5, y: 0)
                .rotated(by: direction * 0.4)
            card.alpha = 0
        }, completion: { _ in completion() })
    }

    @objc func yesTapped() {
        guard currentIndex < movies.count else { return }
        vote("yes")
    }

    @objc func noTapped() {
        guard currentIndex < movies.count else { return }
        vote("no")
    }

    func vote(_ choice: String) {
        guard let session, let uid, currentIndex < movies.count else { return }
        let movie = movies[currentIndex]
        currentIndex += 1
        firestoreService.recordVote(sessionID: session.id, uid: uid, movieID: movie.id, vote: choice) { _ in }
        showNextCard()

        if currentIndex >= movies.count {
            checkCompletion()
        }
    }

    func checkCompletion() {
        guard let session, let uid else { return }
        firestoreService.getSession(id: session.id) { [weak self] updated in
            guard let self, let updated else { return }
            if updated.allParticipantsFinished() {
                let matches = updated.matchingMovies()
                let resultID = matches.randomElement()?.id
                self.firestoreService.finaliseSession(sessionID: session.id, result: resultID) { _ in }
            }
        }
    }

    @objc func closeTapped() {
        dismiss(animated: true)
    }
}

// MARK: - Listener

private extension SwipeSessionViewController {
    func startListening() {
        guard let session else { return }
        sessionListener = firestoreService.observeSession(id: session.id) { [weak self] updated in
            guard let self, let updated else { return }
            if updated.status == .done {
                self.sessionListener?.remove()
                DispatchQueue.main.async {
                    self.onFinished?(updated)
                }
            }
        }
    }
}
