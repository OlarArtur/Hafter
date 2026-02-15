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
        b.tintColor = UIColor(red: 0.14, green: 0.13, blue: 0.21, alpha: 1)
        b.layer.cornerRadius = 10
        return b
    }()

    private let tableView: UITableView = {
        let t = UITableView(frame: .zero, style: .plain)
        t.translatesAutoresizingMaskIntoConstraints = false
        t.backgroundColor = .systemBackground
        t.separatorStyle = .none
        return t
    }()

    private let separatorView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(red: 0.235, green: 0.235, blue: 0.263, alpha: 0.29)
        return v
    }()

    private let headerContainerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemBackground
        return v
    }()

    private var bottomConstraint: NSLayoutConstraint!

    private lazy var customSearchBar: CustomSearchBar = CustomSearchBar()

    private var addDataSource: AddTableViewDataSource?
    private var addDelegate: AddTableViewDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
        bindViewModel()
        setupUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
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

        let bottomSpacer = UIView()
        bottomSpacer.translatesAutoresizingMaskIntoConstraints = false
        bottomSpacer.backgroundColor = .clear
        view.addSubview(bottomSpacer)

        addButton.addTarget(self, action: #selector(addAction), for: .touchUpInside)

        NSLayoutConstraint.activate([
            headerContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            headerContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            headerContainerView.heightAnchor.constraint(equalToConstant: 40),

            addLabel.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor, constant: 10),
            addLabel.centerYAnchor.constraint(equalTo: headerContainerView.centerYAnchor),
            addLabel.trailingAnchor.constraint(lessThanOrEqualTo: addButton.leadingAnchor, constant: -10),

            addButton.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor, constant: -10),
            addButton.centerYAnchor.constraint(equalTo: headerContainerView.centerYAnchor),
            addButton.widthAnchor.constraint(equalTo: addButton.heightAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 32),

            separatorView.topAnchor.constraint(equalTo: headerContainerView.bottomAnchor),
            separatorView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            separatorView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            separatorView.heightAnchor.constraint(equalToConstant: 1),

            tableView.topAnchor.constraint(equalTo: separatorView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),

            bottomSpacer.widthAnchor.constraint(equalToConstant: 100),
            bottomSpacer.heightAnchor.constraint(equalToConstant: 20),
            bottomSpacer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            bottomSpacer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        bottomConstraint = tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        bottomConstraint.isActive = true
    }

    func setupUI() {
        navigationItem.titleView = customSearchBar
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage.image(named: ImageConstants.back), style: .plain, target: self, action: #selector(backTapped))
        navigationItem.leftBarButtonItem?.tintColor = #colorLiteral(red: 0.6588235294, green: 0.7215686275, blue: 0.7843137255, alpha: 1)

        customSearchBar.delegate = self
        customSearchBar.becomeFirstResponder()

        addButton.isEnabled = false
        setupTableView()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotification(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
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
        tableView.rowHeight = 30
        addDataSource = AddTableViewDataSource(viewModel: viewModel) { [weak self] in
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
              let value = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }

        let isKeyboardShowing = notification.name == UIResponder.keyboardWillShowNotification
        if isKeyboardShowing {
            let newHeight = value.cgRectValue.height - view.safeAreaInsets.bottom
            bottomConstraint.constant = -newHeight
            UIView.animate(withDuration: 0.1) {
                self.view.layoutIfNeeded()
            }
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
