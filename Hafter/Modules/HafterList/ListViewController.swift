//
//  ListViewController.swift
//  Hafter
//
//  Created by Artur Olar on 07.04.2022.
//

import UIKit

final class ListViewController: BaseViewController<ListViewModelProtocol>, CustomAlertRouterProtocol {    
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var emptyView: UIView!
    
    private var dataSource: ListTableViewDataSource?
    private var listDelegate: ListTableViewDelegate?
    
    private let imageLoader = ImageLoader()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bindViewModel()
        setupTableView()
        emptyView.isHidden = (viewModel?.numberOfItems() ?? 0) > 0
    }
    
    @IBAction private func closeAction(_ sender: UIButton) {
        dismiss(animated: true)
    }
}

private extension ListViewController {
    
    func bindViewModel() {
        
        viewModel?.reloadData = { [weak self] in
            self?.tableView.reloadData()
        }
        
        viewModel?.showError = { [weak self] error in
            self?.showAlert(title: "Error", message: "\(error.localizedDescription)", actionTitle: nil)
        }
        
        viewModel?.start()
    }
    
    func setupTableView() {
        guard let viewModel = viewModel else { return }
        tableView.registerNibCell(ListTableViewCell.self)
        tableView.rowHeight = 100
        tableView.separatorStyle = .none
        dataSource = ListTableViewDataSource(viewModel: viewModel, imageLoader: imageLoader)
        listDelegate = ListTableViewDelegate(viewModel: viewModel)
        tableView.dataSource = dataSource
        tableView.delegate = listDelegate
    }
}
