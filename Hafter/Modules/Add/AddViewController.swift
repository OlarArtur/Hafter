//
//  AddViewController.swift
//  Hafter
//
//  Created by Artur Olar on 01.04.2022.
//

import UIKit

final class AddViewController: BaseViewController<AddViewModelProtocol>, CustomAlertRouterProtocol {

    private let addLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 17)
        l.text = ""
        return l
    }()

    private let addButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(UIImage(named: "add_plus"), for: .normal)
        b.tintColor = DS.Color.accent
        b.layer.cornerRadius = DS.Radius.chip
        return b
    }()

    private let tableView: UITableView = {
        let t = UITableView(frame: .zero, style: .insetGrouped)
        t.translatesAutoresizingMaskIntoConstraints = false
        t.backgroundColor = .systemGroupedBackground
        t.separatorStyle = .none
        t.keyboardDismissMode = .onDrag
        return t
    }()

    private let separatorView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.separator
        return v
    }()

    private let headerContainerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .secondarySystemGroupedBackground
        v.layer.cornerRadius = 12
        v.clipsToBounds = true
        return v
    }()

    private let tmdbAttributionView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemGroupedBackground
        return v
    }()

    private let tmdbLogoView: UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.contentMode = .scaleAspectFit
        v.image = UIImage(named: "TMDb_logo")
        return v
    }()

    private let tmdbLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "This product uses the TMDB API but is not endorsed or certified by TMDB"
        l.font = .systemFont(ofSize: 14)
        l.textColor = UIColor(red: 0.149, green: 0.196, blue: 0.220, alpha: 1)
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private var bottomConstraint: NSLayoutConstraint!
    private var tmdbAttributionBottomConstraint: NSLayoutConstraint!

    private lazy var customSearchBar: CustomSearchBar = CustomSearchBar()

    private let imageLoader: ImageLoaderProtocol = ImageLoader()

    private var addDataSource: AddTableViewDataSource?
    private var addDelegate: AddTableViewDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
        bindViewModel()
        setupUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        tmdbAttributionBottomConstraint.constant = -view.safeAreaInsets.bottom
    }

    @objc private func addAction() {
        viewModel?.update(title: addLabel.text ?? "")
        addMovie()
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}

private extension AddViewController {

    func setupLayout() {
        view.addSubview(headerContainerView)
        headerContainerView.addSubview(addLabel)
        headerContainerView.addSubview(addButton)
        view.addSubview(separatorView)
        view.addSubview(tableView)
        view.addSubview(tmdbAttributionView)
        tmdbAttributionView.addSubview(tmdbLabel)
        tmdbAttributionView.addSubview(tmdbLogoView)

        addButton.addTarget(self, action: #selector(addAction), for: .touchUpInside)

        NSLayoutConstraint.activate([
            headerContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: DS.Spacing.m),
            headerContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -DS.Spacing.m),
            headerContainerView.heightAnchor.constraint(equalToConstant: 40),

            addLabel.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor, constant: DS.Spacing.xs),
            addLabel.centerYAnchor.constraint(equalTo: headerContainerView.centerYAnchor),
            addLabel.trailingAnchor.constraint(lessThanOrEqualTo: addButton.leadingAnchor, constant: -DS.Spacing.xs),

            addButton.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor, constant: -DS.Spacing.xs),
            addButton.centerYAnchor.constraint(equalTo: headerContainerView.centerYAnchor),
            addButton.widthAnchor.constraint(equalTo: addButton.heightAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 32),

            separatorView.topAnchor.constraint(equalTo: headerContainerView.bottomAnchor),
            separatorView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: DS.Spacing.xs),
            separatorView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -DS.Spacing.xs),
            separatorView.heightAnchor.constraint(equalToConstant: 1),

            tableView.topAnchor.constraint(equalTo: separatorView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),

            tmdbAttributionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tmdbAttributionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tmdbLabel.topAnchor.constraint(equalTo: tmdbAttributionView.topAnchor, constant: 8),
            tmdbLabel.leadingAnchor.constraint(equalTo: tmdbAttributionView.leadingAnchor, constant: 10),
            tmdbLabel.trailingAnchor.constraint(equalTo: tmdbAttributionView.trailingAnchor, constant: -10),

            tmdbLogoView.topAnchor.constraint(equalTo: tmdbLabel.bottomAnchor, constant: 5),
            tmdbLogoView.centerXAnchor.constraint(equalTo: tmdbAttributionView.centerXAnchor),
            tmdbLogoView.widthAnchor.constraint(equalToConstant: 80),
            tmdbLogoView.heightAnchor.constraint(equalToConstant: 20),
            tmdbLogoView.bottomAnchor.constraint(equalTo: tmdbAttributionView.bottomAnchor, constant: -8)
        ])

        bottomConstraint = tableView.bottomAnchor.constraint(equalTo: tmdbAttributionView.topAnchor)
        bottomConstraint.isActive = true

        tmdbAttributionBottomConstraint = tmdbAttributionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        tmdbAttributionBottomConstraint.isActive = true
    }

    func setupUI() {
        navigationController?.navigationBar.tintColor = DS.Color.accent
        navigationItem.titleView = customSearchBar
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage.image(named: ImageConstants.back), style: .plain, target: self, action: #selector(backTapped))
        navigationItem.leftBarButtonItem?.tintColor = DS.Color.navIconLight

        customSearchBar.delegate = self
        customSearchBar.placeholder = "Search movies"
        customSearchBar.becomeFirstResponder()

        addButton.isEnabled = false
        setupTableView()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotification(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotification(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func bindViewModel() {
        viewModel?.reloadData = { [weak self] in
            self?.tableView.reloadData()
        }

        viewModel?.showError = { [weak self] error in
            self?.showAlert(title: "Error", message: "\(error.localizedDescription)", actionTitle: nil)
        }

        viewModel?.updateTitle = { [weak self] title in
            self?.addLabel.text = title ?? self?.customSearchBar.text
        }
    }

    func setupTableView() {
        guard let viewModel = viewModel else { return }
        tableView.registerCell(AddTableViewCell.self)
        addDataSource = AddTableViewDataSource(viewModel: viewModel, imageLoader: imageLoader) { [weak self] in
            self?.viewModel?.update(title: self?.customSearchBar.text ?? "")
            self?.addMovie()
        }
        addDelegate = AddTableViewDelegate(viewModel: viewModel)
        tableView.dataSource = addDataSource
        tableView.delegate = addDelegate
    }

    func addMovie() {
        showChooserView { [weak self] type in
            guard let self = self else { return }
            self.viewModel?.updateSelectedType(type: type)
            self.viewModel?.add(controller: self)
        }
    }

    @objc func keyboardNotification(notification: NSNotification) {
        guard let userInfo = (notification as Notification).userInfo,
              let value = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        let curveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 0
        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)

        let isKeyboardShowing = notification.name == UIResponder.keyboardWillShowNotification
        let keyboardFrameHeight = value.cgRectValue.height

        tmdbAttributionBottomConstraint.constant = isKeyboardShowing ? -keyboardFrameHeight : -view.safeAreaInsets.bottom

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.view.layoutIfNeeded()
        }
    }
}

extension AddViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        addButton.isEnabled = !searchText.isEmpty
        viewModel?.clear()
        guard searchText.count >= 3 else { return }
        viewModel?.search(query: searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text, !query.isEmpty else { return }
        viewModel?.search(query: query)
    }
}
