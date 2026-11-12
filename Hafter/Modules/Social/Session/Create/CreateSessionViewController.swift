//
//  CreateSessionViewController.swift
//  Hafter
//

import UIKit

final class CreateSessionViewController: UIViewController {

    var viewModel: CreateSessionViewModelProtocol?
    var onSessionCreated: ((MovieSession) -> Void)?

    // MARK: - Views

    private let tableView: UITableView = {
        let t = UITableView(frame: .zero, style: .insetGrouped)
        t.translatesAutoresizingMaskIntoConstraints = false
        t.backgroundColor = .systemGroupedBackground
        t.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return t
    }()

    private lazy var createButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Create Session"
        config.baseBackgroundColor = DS.Color.accent
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        return b
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let a = UIActivityIndicatorView(style: .medium)
        a.translatesAutoresizingMaskIntoConstraints = false
        a.hidesWhenStopped = true
        return a
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "New Session with \(viewModel?.friend.displayName ?? "")"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped)
        )
        setupLayout()
        bindViewModel()
        tableView.dataSource = self
        tableView.delegate = self
    }
}

// MARK: - Setup

private extension CreateSessionViewController {

    func setupLayout() {
        view.addSubview(tableView)
        view.addSubview(createButton)
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: createButton.topAnchor, constant: -DS.Spacing.m),

            createButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DS.Spacing.m),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DS.Spacing.m),
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -DS.Spacing.m),
            createButton.heightAnchor.constraint(equalToConstant: 50),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    func bindViewModel() {
        viewModel?.onSessionCreated = { [weak self] session in
            self?.activityIndicator.stopAnimating()
            self?.createButton.isEnabled = true
            let callback = self?.onSessionCreated
            self?.dismiss(animated: true) {
                callback?(session)
            }
        }
        viewModel?.onError = { [weak self] message in
            self?.activityIndicator.stopAnimating()
            self?.createButton.isEnabled = true
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }

    @objc func createTapped() {
        createButton.isEnabled = false
        activityIndicator.startAnimating()
        viewModel?.createSession()
    }

    @objc func cancelTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource

extension CreateSessionViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return SessionMode.allCases.count
        case 1: return [HereafterMovieType.foremost, .possibly, .ifNothingElse].count
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "Mode" : "From List"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = cell.defaultContentConfiguration()

        if indexPath.section == 0 {
            let mode = SessionMode.allCases[indexPath.row]
            config.text = mode.title
            config.image = UIImage(systemName: mode.systemImage)
            config.imageProperties.tintColor = DS.Color.accent
            cell.accessoryType = (viewModel?.selectedMode == mode) ? .checkmark : .none
        } else {
            let lists: [HereafterMovieType] = [.foremost, .possibly, .ifNothingElse]
            let list = lists[indexPath.row]
            config.text = list.title
            cell.accessoryType = (viewModel?.selectedList == list) ? .checkmark : .none
        }

        cell.contentConfiguration = config
        return cell
    }
}

// MARK: - UITableViewDelegate

extension CreateSessionViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            viewModel?.selectedMode = SessionMode.allCases[indexPath.row]
        } else {
            let lists: [HereafterMovieType] = [.foremost, .possibly, .ifNothingElse]
            viewModel?.selectedList = lists[indexPath.row]
        }
        tableView.reloadData()
    }
}
