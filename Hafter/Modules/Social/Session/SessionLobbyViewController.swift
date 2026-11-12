//
//  SessionLobbyViewController.swift
//  Hafter
//
//  Waits until each person has added a shelf, or the creator starts early.
//

import UIKit
import FirebaseFirestore

final class SessionLobbyViewController: UIViewController {

    var session: MovieSession?
    var uid: String?
    var localService: LocalServiceProtocol?
    var onReady: ((MovieSession) -> Void)?

    private let firestoreService: FirestoreServiceProtocol = FirestoreService.shared
    private var sessionListener: ListenerRegistration?
    private var selectedList: HereafterMovieType = .foremost
    private var didHandOff = false
    private var isWorking = false

    private let summaryLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = DS.Typography.title2
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private let peopleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = DS.Typography.body
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private let sharedLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = DS.Typography.callout
        label.textColor = DS.Color.brandIndigo
        label.numberOfLines = 0
        return label
    }()

    private let listStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = DS.Spacing.xs
        return stack
    }()

    private lazy var contributeButton = filledButton("Add my list", action: #selector(contributeTapped))
    private lazy var startButton = filledButton("Start now", action: #selector(startTapped))

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = session?.mode.title ?? "Session"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeTapped))
        setupLayout()
        buildListButtons()
        refresh()
        startListening()
    }

    deinit { sessionListener?.remove() }

    private func filledButton(_ title: String, action: Selector) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = DS.Color.accent
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func setupLayout() {
        view.addSubview(summaryLabel)
        view.addSubview(peopleLabel)
        view.addSubview(sharedLabel)
        view.addSubview(listStack)
        view.addSubview(contributeButton)
        view.addSubview(startButton)
        NSLayoutConstraint.activate([
            summaryLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: DS.Spacing.l),
            summaryLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DS.Spacing.m),
            summaryLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DS.Spacing.m),
            peopleLabel.topAnchor.constraint(equalTo: summaryLabel.bottomAnchor, constant: DS.Spacing.s),
            peopleLabel.leadingAnchor.constraint(equalTo: summaryLabel.leadingAnchor),
            peopleLabel.trailingAnchor.constraint(equalTo: summaryLabel.trailingAnchor),
            sharedLabel.topAnchor.constraint(equalTo: peopleLabel.bottomAnchor, constant: DS.Spacing.m),
            sharedLabel.leadingAnchor.constraint(equalTo: summaryLabel.leadingAnchor),
            sharedLabel.trailingAnchor.constraint(equalTo: summaryLabel.trailingAnchor),
            listStack.topAnchor.constraint(equalTo: sharedLabel.bottomAnchor, constant: DS.Spacing.l),
            listStack.leadingAnchor.constraint(equalTo: summaryLabel.leadingAnchor),
            listStack.trailingAnchor.constraint(equalTo: summaryLabel.trailingAnchor),
            contributeButton.topAnchor.constraint(equalTo: listStack.bottomAnchor, constant: DS.Spacing.m),
            contributeButton.leadingAnchor.constraint(equalTo: summaryLabel.leadingAnchor),
            contributeButton.trailingAnchor.constraint(equalTo: summaryLabel.trailingAnchor),
            contributeButton.heightAnchor.constraint(equalToConstant: 50),
            startButton.topAnchor.constraint(equalTo: contributeButton.bottomAnchor, constant: DS.Spacing.s),
            startButton.leadingAnchor.constraint(equalTo: summaryLabel.leadingAnchor),
            startButton.trailingAnchor.constraint(equalTo: summaryLabel.trailingAnchor),
            startButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func buildListButtons() {
        let lists: [HereafterMovieType] = [.foremost, .possibly, .ifNothingElse]
        for list in lists {
            let button = UIButton(type: .system)
            button.tag = lists.firstIndex(of: list) ?? 0
            button.titleLabel?.font = DS.Typography.body
            button.contentHorizontalAlignment = .leading
            button.addTarget(self, action: #selector(listTapped(_:)), for: .touchUpInside)
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true
            listStack.addArrangedSubview(button)
        }
        updateListButtons()
    }

    private func updateListButtons() {
        let lists: [HereafterMovieType] = [.foremost, .possibly, .ifNothingElse]
        for case let button as UIButton in listStack.arrangedSubviews {
            let list = lists[button.tag]
            let mark = list == selectedList ? "✓  " : "    "
            button.setTitle(mark + list.title, for: .normal)
        }
    }

    private func refresh() {
        guard let session, let uid else { return }
        let contributed = session.contributions[uid]?.isEmpty == false
        let waiting = session.participants.filter { session.contributions[$0]?.isEmpty != false }
        summaryLabel.text = "\(session.movies.count) movies in the pool"
        if waiting.isEmpty {
            peopleLabel.text = "Everyone has added a list."
        } else {
            peopleLabel.text = "Waiting for \(waiting.count) more \(waiting.count == 1 ? "list" : "lists")."
        }
        let shared = SessionPool.sharedMovies(session.movies)
        if shared.isEmpty {
            sharedLabel.text = "Movies on more than one list will be marked here."
        } else {
            sharedLabel.text = shared.map { "\($0.title) · \($0.sharedLabel ?? "Shared")" }.joined(separator: "\n")
        }
        listStack.isHidden = contributed
        contributeButton.isHidden = contributed
        let creatorCanStart = uid == session.createdBy && session.status == .pending
        startButton.isHidden = creatorCanStart == false
        let title = session.mode == .random ? "Pick now" : "Start now"
        var config = startButton.configuration
        config?.title = title
        startButton.configuration = config
    }

    private func startListening() {
        guard let session else { return }
        sessionListener = firestoreService.observeSession(id: session.id) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                if SocialErrorMessage.isOffline(error) == false {
                    self.presentNotice(SocialErrorMessage.userVisible(error, offline: "Couldn't update the session. Check your connection and try again."))
                }
            case .success(nil):
                self.presentNotice("This session was deleted.")
            case .success(let updated?):
                self.session = updated
                self.refresh()
                if updated.status != .pending {
                    self.handOff(updated)
                }
            }
        }
    }

    @objc private func listTapped(_ sender: UIButton) {
        let lists: [HereafterMovieType] = [.foremost, .possibly, .ifNothingElse]
        selectedList = lists[sender.tag]
        updateListButtons()
    }

    @objc private func contributeTapped() {
        guard isWorking == false, let session, let uid, let localService else { return }
        let movies = localService.getMovies(type: selectedList).map {
            SessionMovie(id: $0.movie.id, title: $0.movie.title, posterPath: $0.movie.posterPath, year: $0.movie.year(), contributors: [uid])
        }
        guard movies.isEmpty == false else {
            presentNotice("Your \(selectedList.title) list is empty. Add some movies first.")
            return
        }
        isWorking = true
        contributeButton.isEnabled = false
        firestoreService.contributeMovies(sessionID: session.id, uid: uid, listName: selectedList.rawValue, movies: movies) { [weak self] result in
            guard let self else { return }
            self.isWorking = false
            self.contributeButton.isEnabled = true
            switch result {
            case .failure(let error):
                self.presentNotice(SocialErrorMessage.userVisible(error, offline: "Couldn't add your list. Check your connection and try again."))
            case .success(let updated):
                self.session = updated
                self.refresh()
                if SessionPool.everyoneHasContributed(participants: updated.participants, contributions: updated.contributions) {
                    self.begin(updated)
                }
            }
        }
    }

    @objc private func startTapped() {
        guard let session else { return }
        begin(session)
    }

    private func begin(_ session: MovieSession) {
        guard isWorking == false else { return }
        isWorking = true
        startButton.isEnabled = false
        let finish: (Error?) -> Void = { [weak self] error in
            guard let self else { return }
            self.isWorking = false
            self.startButton.isEnabled = true
            if let error {
                self.presentNotice(SocialErrorMessage.userVisible(error, offline: "Couldn't start the session. Check your connection and try again."))
            }
        }
        if session.mode == .random {
            firestoreService.finaliseSession(sessionID: session.id, result: session.movies.randomElement()?.id, completion: finish)
        } else {
            firestoreService.startSession(sessionID: session.id, completion: finish)
        }
    }

    private func handOff(_ session: MovieSession) {
        guard didHandOff == false else { return }
        didHandOff = true
        sessionListener?.remove()
        sessionListener = nil
        let callback = onReady
        dismiss(animated: true) {
            callback?(session)
        }
    }

    private func presentNotice(_ message: String) {
        let alert = UIAlertController(title: "Session", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func closeTapped() {
        sessionListener?.remove()
        sessionListener = nil
        dismiss(animated: true)
    }
}
