//
//  FriendsViewController.swift
//  Hafter
//

import UIKit

final class FriendsViewController: UIViewController {

    var viewModel: FriendsViewModelProtocol?

    // MARK: - Views

    private lazy var tableView: UITableView = {
        let t = UITableView(frame: .zero, style: .insetGrouped)
        t.translatesAutoresizingMaskIntoConstraints = false
        t.backgroundColor = .systemGroupedBackground
        t.separatorStyle = .singleLine
        t.dataSource = self
        t.delegate = self
        t.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        t.register(FriendCell.self, forCellReuseIdentifier: FriendCell.reuseId)
        t.register(SessionInviteCell.self, forCellReuseIdentifier: SessionInviteCell.reuseId)
        return t
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Add a friend by their share code"
        l.font = DS.Typography.callout
        l.textColor = DS.Color.labelMuted
        l.textAlignment = .center
        l.numberOfLines = 0
        l.isHidden = true
        return l
    }()

    private let deletingOverlay: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.85)
        v.isHidden = true
        return v
    }()

    private let deletingSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        return spinner
    }()

    private let deletingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Deleting account…"
        label.font = DS.Typography.body
        label.textColor = DS.Color.labelMuted
        label.textAlignment = .center
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Friends"
        view.backgroundColor = .systemGroupedBackground
        setupNavigationBar()
        setupLayout()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel?.load()
    }
}

// MARK: - Setup

private extension FriendsViewController {

    func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "person.badge.plus"),
            style: .plain,
            target: self,
            action: #selector(addFriendTapped)
        )
        navigationItem.rightBarButtonItem?.tintColor = DS.Color.accent
    }

    func setupLayout() {
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        view.addSubview(deletingOverlay)
        deletingOverlay.addSubview(deletingSpinner)
        deletingOverlay.addSubview(deletingLabel)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DS.Spacing.xl),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DS.Spacing.xl),

            deletingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            deletingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            deletingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            deletingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            deletingSpinner.centerXAnchor.constraint(equalTo: deletingOverlay.centerXAnchor),
            deletingSpinner.centerYAnchor.constraint(equalTo: deletingOverlay.centerYAnchor, constant: -DS.Spacing.s),
            deletingLabel.topAnchor.constraint(equalTo: deletingSpinner.bottomAnchor, constant: DS.Spacing.s),
            deletingLabel.leadingAnchor.constraint(equalTo: deletingOverlay.leadingAnchor, constant: DS.Spacing.m),
            deletingLabel.trailingAnchor.constraint(equalTo: deletingOverlay.trailingAnchor, constant: -DS.Spacing.m)
        ])
    }

    func bindViewModel() {
        viewModel?.onUpdate = { [weak self] in
            self?.tableView.reloadData()
            let isEmpty = (self?.viewModel?.friends.isEmpty ?? true) && (self?.viewModel?.pendingSessions.isEmpty ?? true)
            self?.emptyLabel.isHidden = !isEmpty
        }
        viewModel?.onError = { [weak self] message in
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
        viewModel?.onDeletingChanged = { [weak self] deleting in
            self?.deletingOverlay.isHidden = !deleting
            self?.navigationItem.rightBarButtonItem?.isEnabled = !deleting
            self?.tableView.isUserInteractionEnabled = !deleting
            self?.navigationController?.isModalInPresentation = deleting
            if deleting {
                self?.deletingSpinner.startAnimating()
            } else {
                self?.deletingSpinner.stopAnimating()
            }
        }
    }

    @objc func addFriendTapped() {
        let alert = UIAlertController(title: "Add Friend", message: "Enter their 6-character share code", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "e.g. ABC123"
            tf.autocapitalizationType = .allCharacters
            tf.autocorrectionType = .no
        }
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self, weak alert] _ in
            guard let code = alert?.textFields?.first?.text, !code.isEmpty else { return }
            self?.viewModel?.addFriend(shareCode: code)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc func deleteAccountTapped() {
        let alert = UIAlertController(
            title: "Delete Account?",
            message: "This permanently deletes your Hafter sign-in, share code, and friend links. Movie sessions you created are deleted. Sessions a friend created stay open, with you removed. Movie lists saved on this device stay on this device. Apple will ask you to confirm.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Delete Account", style: .destructive) { [weak self] _ in
            guard let self else { return }
            self.viewModel?.deleteAccount(from: self)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension FriendsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 4 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 1
        case 2: return viewModel?.pendingSessions.count ?? 0
        case 3: return viewModel?.friends.count ?? 0
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Your Share Code"
        case 1: return "Account"
        case 2: return (viewModel?.pendingSessions.isEmpty ?? true) ? nil : "Invitations"
        case 3: return (viewModel?.friends.isEmpty ?? true) ? nil : "Friends"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            let code = viewModel?.currentUser?.shareCode ?? "–"
            var config = cell.defaultContentConfiguration()
            config.text = code
            config.textProperties.font = UIFont.monospacedSystemFont(ofSize: 24, weight: .bold)
            config.textProperties.color = DS.Color.accent
            config.textProperties.alignment = .center
            config.secondaryText = "Share this code with a friend to connect"
            config.secondaryTextProperties.font = DS.Typography.caption
            config.secondaryTextProperties.color = .secondaryLabel
            config.secondaryTextProperties.alignment = .center
            cell.contentConfiguration = config
            cell.selectionStyle = .none
            return cell

        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            var config = cell.defaultContentConfiguration()
            config.text = "Delete Account"
            config.textProperties.font = DS.Typography.body
            config.textProperties.color = .systemRed
            config.secondaryText = "Permanently removes your sign-in, friends, and sessions you created"
            config.secondaryTextProperties.font = DS.Typography.caption
            config.secondaryTextProperties.color = .secondaryLabel
            cell.contentConfiguration = config
            cell.selectionStyle = .default
            return cell

        case 2:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SessionInviteCell.reuseId, for: indexPath) as? SessionInviteCell,
                  let session = viewModel?.pendingSessions[indexPath.row] else {
                return UITableViewCell()
            }
            cell.configure(with: session)
            return cell

        case 3:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: FriendCell.reuseId, for: indexPath) as? FriendCell,
                  let friend = viewModel?.friends[indexPath.row] else {
                return UITableViewCell()
            }
            cell.configure(with: friend)
            return cell

        default: return UITableViewCell()
        }
    }
}

// MARK: - UITableViewDelegate

extension FriendsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0: return 80
        case 1: return 64
        case 2: return 60
        case 3: return 56
        default: return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 1:
            deleteAccountTapped()
        case 2:
            guard let session = viewModel?.pendingSessions[indexPath.row] else { return }
            viewModel?.onSessionTapped(session)
        case 3:
            guard let friend = viewModel?.friends[indexPath.row] else { return }
            viewModel?.onCreateSessionTapped(with: friend)
        default: break
        }
    }
}

// MARK: - FriendCell

private final class FriendCell: UITableViewCell {

    static let reuseId = "FriendCell"

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = DS.Typography.body
        return l
    }()

    private let codeLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = DS.Typography.caption
        l.textColor = .secondaryLabel
        return l
    }()

    private let movieButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle("Pick a movie", for: .normal)
        b.titleLabel?.font = DS.Typography.caption
        b.tintColor = DS.Color.accent
        b.isUserInteractionEnabled = false
        return b
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with friend: SocialUser) {
        nameLabel.text = friend.displayName
        codeLabel.text = friend.shareCode
    }

    private func setupLayout() {
        contentView.addSubview(nameLabel)
        contentView.addSubview(codeLabel)
        contentView.addSubview(movieButton)
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DS.Spacing.m),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: DS.Spacing.xs),
            codeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DS.Spacing.m),
            codeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            movieButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DS.Spacing.m),
            movieButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
}

// MARK: - SessionInviteCell

private final class SessionInviteCell: UITableViewCell {

    static let reuseId = "SessionInviteCell"

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = DS.Typography.body
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = DS.Typography.caption
        l.textColor = .secondaryLabel
        return l
    }()

    private let badge: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = DS.Color.accent
        v.layer.cornerRadius = 4
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
        accessoryType = .disclosureIndicator
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with session: MovieSession) {
        titleLabel.text = "Session · \(session.mode.title)"
        switch session.status {
        case .pending:
            subtitleLabel.text = "\(session.movies.count) movies · add your list"
        case .active:
            subtitleLabel.text = "\(session.movies.count) movies · in progress"
        case .done:
            subtitleLabel.text = "Result ready"
        }
    }

    private func setupLayout() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(badge)
        NSLayoutConstraint.activate([
            badge.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DS.Spacing.m),
            badge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            badge.widthAnchor.constraint(equalToConstant: 8),
            badge.heightAnchor.constraint(equalToConstant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: badge.trailingAnchor, constant: DS.Spacing.xs),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: DS.Spacing.xs),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2)
        ])
    }
}
