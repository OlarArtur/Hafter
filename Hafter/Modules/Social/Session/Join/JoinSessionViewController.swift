//
//  JoinSessionViewController.swift
//  Hafter
//

import UIKit

final class JoinSessionViewController: UIViewController {

    var session: MovieSession?
    var uid: String?
    var onJoined: ((MovieSession) -> Void)?

    private let firestoreService: FirestoreServiceProtocol = FirestoreService.shared

    // MARK: - Views

    private let containerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = DS.Radius.sheet
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = DS.Typography.title1
        l.text = "You're Invited!"
        l.textAlignment = .center
        return l
    }()

    private let detailLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = DS.Typography.callout
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        l.textAlignment = .center
        return l
    }()

    private let modeIcon: UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.contentMode = .scaleAspectFit
        v.tintColor = DS.Color.accent
        return v
    }()

    private lazy var acceptButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Join Session"
        config.baseBackgroundColor = DS.Color.accent
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(acceptTapped), for: .touchUpInside)
        return b
    }()

    private lazy var declineButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "Decline"
        config.baseForegroundColor = .secondaryLabel
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(declineTapped), for: .touchUpInside)
        return b
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DS.Color.accent.withAlphaComponent(0.15)
        setupLayout()
        configure()
    }
}

// MARK: - Setup

private extension JoinSessionViewController {

    func setupLayout() {
        view.addSubview(containerView)
        containerView.addSubview(modeIcon)
        containerView.addSubview(titleLabel)
        containerView.addSubview(detailLabel)
        containerView.addSubview(acceptButton)
        containerView.addSubview(declineButton)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.topAnchor.constraint(equalTo: view.centerYAnchor),

            modeIcon.topAnchor.constraint(equalTo: containerView.topAnchor, constant: DS.Spacing.l),
            modeIcon.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            modeIcon.widthAnchor.constraint(equalToConstant: 44),
            modeIcon.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.topAnchor.constraint(equalTo: modeIcon.bottomAnchor, constant: DS.Spacing.m),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: DS.Spacing.m),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -DS.Spacing.m),

            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: DS.Spacing.s),
            detailLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: DS.Spacing.m),
            detailLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -DS.Spacing.m),

            acceptButton.topAnchor.constraint(equalTo: detailLabel.bottomAnchor, constant: DS.Spacing.l),
            acceptButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: DS.Spacing.m),
            acceptButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -DS.Spacing.m),
            acceptButton.heightAnchor.constraint(equalToConstant: 50),

            declineButton.topAnchor.constraint(equalTo: acceptButton.bottomAnchor, constant: DS.Spacing.xs),
            declineButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
        ])
    }

    func configure() {
        guard let session else { return }
        let mode = session.mode
        modeIcon.image = UIImage(systemName: mode.systemImage)
        detailLabel.text = "\(session.movies.count) movies · \(mode.title)"
    }

    @objc func acceptTapped() {
        guard let session, let uid else { return }
        acceptButton.isEnabled = false
        firestoreService.acceptSession(sessionID: session.id, uid: uid) { [weak self] error in
            if let error {
                self?.acceptButton.isEnabled = true
                self?.presentError(SocialErrorMessage.userVisible(
                    error,
                    offline: "Couldn't join the session. Check your connection and try again."
                ))
                return
            }
            self?.firestoreService.getSession(id: session.id) { [weak self] updated, error in
                let resolved: MovieSession
                if let updated {
                    resolved = updated
                } else if let error, SocialErrorMessage.isOffline(error) {
                    var fallback = session
                    fallback.status = .active
                    resolved = fallback
                } else {
                    self?.acceptButton.isEnabled = true
                    self?.presentError("This session is no longer available.")
                    return
                }
                let callback = self?.onJoined
                self?.dismiss(animated: true) {
                    callback?(resolved)
                }
            }
        }
    }

    @objc func declineTapped() {
        guard let session, let uid else {
            dismiss(animated: true)
            return
        }
        declineButton.isEnabled = false
        firestoreService.declineSession(sessionID: session.id, uid: uid) { [weak self] error in
            if let error {
                self?.declineButton.isEnabled = true
                self?.presentError(SocialErrorMessage.userVisible(
                    error,
                    offline: "Couldn't decline the invitation. Check your connection and try again."
                ))
                return
            }
            self?.dismiss(animated: true)
        }
    }

    func presentError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
