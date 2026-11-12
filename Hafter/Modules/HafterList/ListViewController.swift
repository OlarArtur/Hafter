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

    private let listTitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = DS.Typography.display
        l.textColor = DS.Color.navIconDark
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.7
        return l
    }()

    private let countLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = DS.Typography.callout
        l.textColor = DS.Color.navIconDark.withAlphaComponent(0.55)
        return l
    }()

    private let closeButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(UIImage(systemName: "xmark"), for: .normal)
        b.tintColor = DS.Color.navIconDark
        b.backgroundColor = UIColor.black.withAlphaComponent(0.10)
        b.layer.cornerRadius = 16
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
        l.text = "Nothing here yet"
        l.font = DS.Typography.title2
        l.textColor = DS.Color.labelMuted
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
        listTitleLabel.text = viewModel?.listTitle
        updateCountLabel()
    }

    @objc private func closeAction() {
        dismiss(animated: true)
    }
}

private extension ListViewController {

    func setupLayout() {
        view.addSubview(headerView)
        headerView.addSubview(listTitleLabel)
        headerView.addSubview(countLabel)
        headerView.addSubview(closeButton)
        view.addSubview(tableView)
        view.addSubview(emptyView)
        emptyView.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),

            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -DS.Spacing.m),
            closeButton.topAnchor.constraint(equalTo: headerView.topAnchor, constant: DS.Spacing.s),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            listTitleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: DS.Spacing.s),
            listTitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: DS.Spacing.m),
            listTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor, constant: -DS.Spacing.s),

            countLabel.topAnchor.constraint(equalTo: listTitleLabel.bottomAnchor, constant: 2),
            countLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: DS.Spacing.m),
            countLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -DS.Spacing.s),

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

    func updateCountLabel() {
        let count = viewModel?.numberOfItems() ?? 0
        countLabel.text = count == 1 ? "1 movie" : "\(count) movies"
    }

    func bindViewModel() {
        viewModel?.reloadData = { [weak self] in
            self?.tableView.reloadData()
            self?.emptyView.isHidden = (self?.viewModel?.numberOfItems() ?? 0) > 0
            self?.updateCountLabel()
        }

        viewModel?.showError = { [weak self] error in
            self?.showAlert(title: "Error", message: "\(error.localizedDescription)", actionTitle: nil)
        }

        viewModel?.start()
        viewModel?.onNeedsViewedDetails = { [weak self] finish in
            guard let self else { return }
            ViewedDetailsEditor.present(on: self, completion: finish)
        }
    }

    func setupTableView() {
        guard let viewModel = viewModel else { return }
        tableView.registerCell(ListTableViewCell.self)
        tableView.rowHeight = 120
        tableView.separatorStyle = .none
        dataSource = ListTableViewDataSource(viewModel: viewModel, imageLoader: imageLoader)
        listDelegate = ListTableViewDelegate(viewModel: viewModel)
        tableView.dataSource = dataSource
        tableView.delegate = listDelegate
    }
}
