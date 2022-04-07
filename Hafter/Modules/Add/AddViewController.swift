//
//  AddViewController.swift
//  Hafter
//
//  Created by Artur Olar on 01.04.2022.
//

import UIKit

final class AddViewController: BaseViewController<AddViewModelProtocol>, CustomAlertRouterProtocol {
    
    @IBOutlet private weak var addLabel: UILabel!
    @IBOutlet private weak var addButton: UIButton!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var bottomConstraint: NSLayoutConstraint!
    
    private lazy var customSearchBar: CustomSearchBar = CustomSearchBar()
    
    private var addDataSource: AddTableViewDataSource?
    private var addDelegate: AddTableViewDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        bindViewModel()
        setupUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    @IBAction func addAction(_ sender: UIButton) {
        showChooserView { [weak self] type in
            guard let self = self else { return }
            self.viewModel?.updateSelectedType(type: type)
            self.viewModel?.add(controller: self)
        }
    }
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}

private extension AddViewController {
    
    func setupUI() {
        
        navigationItem.titleView = customSearchBar
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage.image(named: "back"), style: .plain, target: self, action: #selector(backTapped))
        navigationItem.leftBarButtonItem?.tintColor = #colorLiteral(red: 0.6588235294, green: 0.7215686275, blue: 0.7843137255, alpha: 1)
        
        customSearchBar.delegate = self
        customSearchBar.becomeFirstResponder()
        
        if let text = addLabel.text, text != "" {
            addButton.isEnabled = false
        } else {
            addButton.isEnabled = false
        }
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
        tableView.registerNibCell(AddTableViewCell.self)
        tableView.rowHeight = 30
        tableView.separatorStyle = .none
        addDataSource = AddTableViewDataSource(viewModel: viewModel)
        addDelegate = AddTableViewDelegate(viewModel: viewModel)
        tableView.dataSource = addDataSource
        tableView.delegate = addDelegate
    }
    
    @objc func keyboardNotification(notification: NSNotification) {
        guard let userInfo = (notification as Notification).userInfo, let value = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        
        if ((userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue) != nil {
            let isKeyboardShowing = notification.name == UIResponder.keyboardWillShowNotification
            var newHeight: CGFloat
            
            if isKeyboardShowing {
                newHeight = value.cgRectValue.height - view.safeAreaInsets.bottom
                bottomConstraint.constant = newHeight
                UIView.animate(withDuration: 0.1) {
                    self.view.layoutIfNeeded()
                }
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
