//
//  AddViewController.swift
//  Hafter
//
//  Created by Artur Olar on 01.04.2022.
//

import UIKit

final class AddViewController: BaseViewController<AddViewModelProtocol> {
    
    @IBOutlet private weak var searchBar: CustomSearchBar!
    @IBOutlet private weak var addLabel: UILabel!
    @IBOutlet private weak var addButton: UIButton!
    @IBOutlet private weak var tableView: UITableView!
    
    private var addDataSource: AddTableViewDataSource?
    private var addDelegate: AddTableViewDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        bindViewModel()
        setupUI()
    }
    
    @IBAction func addAction(_ sender: UIButton) {
        viewModel?.add(controller: self)
    }
}

private extension AddViewController {
    
    func setupUI() {
        guard let viewModel = viewModel else { return }
        
        searchBar.delegate = self
        searchBar.becomeFirstResponder()
        
        if let text = addLabel.text, text != "" {
            addButton.isEnabled = false
        } else {
            addButton.isEnabled = false
        }
        
        tableView.registerNibCell(AddTableViewCell.self)
        tableView.rowHeight = 30
        addDataSource = AddTableViewDataSource(viewModel: viewModel)
        addDelegate = AddTableViewDelegate(viewModel: viewModel)
        tableView.dataSource = addDataSource
        tableView.delegate = addDelegate
    }
    
    func bindViewModel() {
        
        viewModel?.reloadData = { [weak self] in
            self?.tableView.reloadData()
        }
        
        viewModel?.showError = { [weak self] error in
            self?.showAlert(title: "Error", message: "\(error.localizedDescription)", actionTitle: nil)
        }
        
        viewModel?.updateTitle = { [weak self] title in
            self?.addLabel.text = title ?? self?.searchBar.text
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
