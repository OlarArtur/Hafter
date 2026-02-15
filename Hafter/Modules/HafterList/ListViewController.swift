//
//  ListViewController.swift
//  Hafter
//
//  Created by Artur Olar on 07.04.2022.
//

import UIKit

final class ListViewController: BaseViewController<ListViewModelProtocol>, CustomAlertRouterProtocol {

    private let headerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .clear
        return v
    }()

    private let closeButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(UIImage(named: "close"), for: .normal)
        return b
    }()

    private let tableView: UITableView = {
        let t = UITableView(frame: .zero, style: .plain)
        t.translatesAutoresizingMaskIntoConstraints = false
        t.backgroundColor = .systemBackground
        return t
    }()

    private let emptyView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemBackground
        v.isHidden = true
        return v
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Empty"
        l.font = .systemFont(ofSize: 17)
        return l
    }()

    private var dataSource: ListTableViewDataSource?
    private var listDelegate: ListTableViewDelegate?

    private let imageLoader = ImageLoader()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayout()
        closeButton.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        bindViewModel()
        setupTableView()
        emptyView.isHidden = (viewModel?.numberOfItems() ?? 0) > 0
        view.backgroundColor = viewModel?.backgrounColor
        tableView.backgroundColor = viewModel?.backgrounColor
        emptyView.backgroundColor = viewModel?.backgrounColor
    }

    @objc private func closeAction() {
        dismiss(animated: true)
    }
}

private extension ListViewController {

    func setupLayout() {
        view.addSubview(headerView)
        headerView.addSubview(closeButton)
        view.addSubview(tableView)
        view.addSubview(emptyView)
        emptyView.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 40),

            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            emptyView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            emptyView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            emptyView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor)
        ])
    }

    func bindViewModel() {
        viewModel?.reloadData = { [weak self] in
            self?.tableView.reloadData()
            self?.emptyView.isHidden = (self?.viewModel?.numberOfItems() ?? 0) > 0
        }

        viewModel?.showError = { [weak self] error in
            self?.showAlert(title: "Error", message: "\(error.localizedDescription)", actionTitle: nil)
        }

        viewModel?.start()
    }

    func setupTableView() {
        guard let viewModel = viewModel else { return }
        tableView.registerCell(ListTableViewCell.self)
        tableView.rowHeight = 100
        tableView.separatorStyle = .none
        dataSource = ListTableViewDataSource(viewModel: viewModel, imageLoader: imageLoader)
        listDelegate = ListTableViewDelegate(viewModel: viewModel)
        tableView.dataSource = dataSource
        tableView.delegate = listDelegate
    }
}
