//
//  VoteSessionViewController.swift
//  Hafter
//

import UIKit
import FirebaseFirestore

final class VoteSessionViewController: UIViewController {

    var session: MovieSession?
    var uid: String?
    var onFinished: ((MovieSession) -> Void)?

    private let firestoreService: FirestoreServiceProtocol = FirestoreService.shared
    private let imageLoader = ImageLoader()
    private var sessionListener: ListenerRegistration?
    private var isFinalising = false
    private var didEndSession = false
    private var didShowOfflineAlert = false

    private var selectedMovieID: String?

    // MARK: - Views

    private lazy var tableView: UITableView = {
        let t = UITableView(frame: .zero, style: .insetGrouped)
        t.translatesAutoresizingMaskIntoConstraints = false
        t.dataSource = self
        t.delegate = self
        t.register(VoteMovieCell.self, forCellReuseIdentifier: VoteMovieCell.reuseId)
        return t
    }()

    private lazy var submitButton: UIButton = {
        var c = UIButton.Configuration.filled()
        c.title = "Submit Vote"
        c.baseBackgroundColor = DS.Color.accent
        c.baseForegroundColor = .white
        c.cornerStyle = .medium
        let b = UIButton(configuration: c)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.isEnabled = false
        b.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
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
        l.text = "Waiting for your friend's vote..."
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
        title = "Vote"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(closeTapped)
        )
        setupLayout()
        startListening()
        if let session, let uid, session.hasUserVotedOnce(uid) {
            showWaiting()
        }
    }

    deinit { sessionListener?.remove() }
}

// MARK: - Setup

private extension VoteSessionViewController {

    func setupLayout() {
        view.addSubview(tableView)
        view.addSubview(submitButton)
        view.addSubview(waitingView)
        waitingView.addSubview(waitingLabel)
        waitingView.addSubview(waitingSpinner)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: submitButton.topAnchor, constant: -DS.Spacing.s),

            submitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DS.Spacing.m),
            submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DS.Spacing.m),
            submitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -DS.Spacing.m),
            submitButton.heightAnchor.constraint(equalToConstant: 50),

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

    @objc func submitTapped() {
        guard let session, let uid, let movieID = selectedMovieID else { return }
        submitButton.isEnabled = false
        firestoreService.recordVote(sessionID: session.id, uid: uid, movieID: movieID, vote: "yes") { [weak self] error in
            guard let self else { return }
            if let error {
                self.submitButton.isEnabled = true
                if SocialErrorMessage.isStale(error) == false {
                    self.showOfflineOnce(SocialErrorMessage.userVisible(
                        error,
                        offline: "Couldn't save your vote. Check your connection and try again."
                    ))
                }
                return
            }
            self.showWaiting()
        }
    }

    func showWaiting() {
        waitingView.isHidden = false
        waitingSpinner.startAnimating()
        submitButton.isEnabled = false
        tableView.isUserInteractionEnabled = false
    }

    @objc func closeTapped() {
        sessionListener?.remove()
        sessionListener = nil
        dismiss(animated: true)
    }
}

// MARK: - Listener

private extension VoteSessionViewController {
    func startListening() {
        guard let session else { return }
        sessionListener?.remove()
        sessionListener = firestoreService.observeSession(id: session.id) { [weak self] result in
            self?.handleSession(result)
        }
    }

    func handleSession(_ result: Result<MovieSession?, Error>) {
        switch result {
        case .failure(let error):
            if SocialErrorMessage.isStale(error) {
                endSession("This session is no longer available.")
            } else {
                showOfflineOnce(SocialErrorMessage.userVisible(
                    error,
                    offline: "Couldn't update the session. Check your connection and try again."
                ))
            }
        case .success(nil):
            endSession("This session was deleted.")
        case .success(let updated?):
            session = updated
            guard let uid else { return }
            if updated.participants.contains(uid) == false {
                endSession("You were removed from this session.")
                return
            }
            if updated.status == .done {
                sessionListener?.remove()
                sessionListener = nil
                onFinished?(updated)
                return
            }
            if updated.hasUserVotedOnce(uid) {
                showWaiting()
            }
            finaliseIfNeeded(updated)
        }
    }

    func finaliseIfNeeded(_ updated: MovieSession) {
        guard updated.isReadyToFinalise(), isFinalising == false else { return }
        isFinalising = true
        firestoreService.finaliseSession(sessionID: updated.id, result: updated.pickedResultID()) { [weak self] error in
            guard let self else { return }
            self.isFinalising = false
            if let error {
                self.showOfflineOnce(
                    SocialErrorMessage.userVisible(
                        error,
                        offline: "Couldn't finish the session. Check your connection and try again."
                    ),
                    retry: { self.finaliseIfNeeded(updated) }
                )
            }
        }
    }

    func endSession(_ message: String) {
        guard didEndSession == false else { return }
        didEndSession = true
        sessionListener?.remove()
        sessionListener = nil
        let alert = UIAlertController(title: "Session ended", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    func showOfflineOnce(_ message: String, retry: (() -> Void)? = nil) {
        guard didShowOfflineAlert == false else { return }
        didShowOfflineAlert = true
        let alert = UIAlertController(title: "Connection problem", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.didShowOfflineAlert = false
            retry?()
        })
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension VoteSessionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        session?.movies.count ?? 0
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { "Pick one movie" }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withReuseIdentifier: VoteMovieCell.reuseId, for: indexPath) as? VoteMovieCell,
              let movie = session?.movies[indexPath.row] else { return UITableViewCell() }
        let isSelected = selectedMovieID == movie.id
        cell.configure(with: movie, selected: isSelected, imageLoader: imageLoader)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension VoteSessionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 72 }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedMovieID = session?.movies[indexPath.row].id
        submitButton.isEnabled = true
        tableView.reloadData()
    }
}

// MARK: - VoteMovieCell

private final class VoteMovieCell: UITableViewCell {
    static let reuseId = "VoteMovieCell"

    private let posterView: UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        v.layer.cornerRadius = DS.Radius.poster
        v.backgroundColor = .systemGroupedBackground
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = DS.Typography.body
        l.numberOfLines = 2
        return l
    }()

    private let yearLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = DS.Typography.caption
        l.textColor = .secondaryLabel
        return l
    }()

    private let checkIcon: UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.image = UIImage(systemName: "checkmark.circle.fill")
        v.tintColor = DS.Color.accent
        v.isHidden = true
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(posterView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(yearLabel)
        contentView.addSubview(checkIcon)
        NSLayoutConstraint.activate([
            posterView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DS.Spacing.m),
            posterView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: DS.Spacing.xs),
            posterView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -DS.Spacing.xs),
            posterView.widthAnchor.constraint(equalTo: posterView.heightAnchor, multiplier: 0.7),
            titleLabel.leadingAnchor.constraint(equalTo: posterView.trailingAnchor, constant: DS.Spacing.s),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: DS.Spacing.s),
            titleLabel.trailingAnchor.constraint(equalTo: checkIcon.leadingAnchor, constant: -DS.Spacing.xs),
            yearLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            yearLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            checkIcon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DS.Spacing.m),
            checkIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkIcon.widthAnchor.constraint(equalToConstant: 24),
            checkIcon.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with movie: SessionMovie, selected: Bool, imageLoader: ImageLoader) {
        titleLabel.text = movie.title
        yearLabel.text = movie.year ?? ""
        checkIcon.isHidden = !selected
        contentView.backgroundColor = selected ? DS.Color.accentDim : .systemBackground
        if let url = movie.posterThumbnailURL {
            imageLoader.imageFromUrl(url: url) { image in
                DispatchQueue.main.async { self.posterView.image = image }
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        posterView.image = nil
        checkIcon.isHidden = true
        contentView.backgroundColor = .systemBackground
    }
}
