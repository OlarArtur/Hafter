//
//  HereafterViewController.swift
//  Hafter
//
//  Created by Artur Olar on 29.03.2022.
//

import UIKit

protocol HereafterViewProtocol: AnyObject {
    func reloadData()
    func updateUI()
    func showError(error: Error)
}

final class HereafterViewController: BaseViewController<HereafterViewModelProtocol> {
    
    deinit {
        print("deinit HereafterViewController")
    }
    
    @IBOutlet private weak var addView: UIView!
    @IBOutlet private weak var randomizeView: UIView!
    
    @IBOutlet private weak var firstlyView: UIView!
    @IBOutlet private weak var secondlyView: UIView!
    @IBOutlet private weak var thirdlyView: UIView!
    
    @IBOutlet private weak var listTableView: UITableView!
    
    private let imageLoader = ImageLoader()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationController()
        
        let addTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(addAction))
        addView.addGestureRecognizer(addTapGestureRecognizer)
        let randomizeTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(randomizeAction))
        randomizeView.addGestureRecognizer(randomizeTapGestureRecognizer)
        
        let firstlyTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(firstlyAction))
        firstlyView.addGestureRecognizer(firstlyTapGestureRecognizer)
        firstlyView.layer.borderWidth = 1
        firstlyView.layer.borderColor = UIColor.foremostColor.cgColor
        
        let secondlyTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(secondlyAction))
        secondlyView.addGestureRecognizer(secondlyTapGestureRecognizer)
        secondlyView.layer.borderWidth = 1
        secondlyView.layer.borderColor = UIColor.possiblyColor.cgColor
        
        let thirdlyTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(thirdlyAction))
        thirdlyView.addGestureRecognizer(thirdlyTapGestureRecognizer)
        thirdlyView.layer.borderWidth = 1
        thirdlyView.layer.borderColor = UIColor.ifNothingElseColor.cgColor
        
        viewModel?.select(type: .foremost, rect: .zero)
        
        setupTableView()
    }
    
    
    @objc private func firstlyAction() {
        viewModel?.select(type: .foremost, rect: .zero)
    }
    
    @objc private func secondlyAction() {
        viewModel?.select(type: .possibly, rect: .zero)
    }
    
    @objc private func thirdlyAction() {
        viewModel?.select(type: .ifNothingElse, rect: .zero)
    }
    
    @objc private func addAction() {
        viewModel?.add()
    }
    
    @objc private func randomizeAction() {
        viewModel?.randomize()
    }
    
    @objc private func menuTapped() {
        viewModel?.openMenu()
    }
    
    @objc private func viewedTapped() {
        viewModel?.openViewed()
    }
}

private extension HereafterViewController {
    
    func setupNavigationController() {
        
//        FUTURE IDEA
//        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage.image(named: ImageConstants.menu), style: .plain, target: self, action: #selector(menuTapped))
//        navigationItem.leftBarButtonItem?.tintColor = #colorLiteral(red: 0.1490196078, green: 0.1960784314, blue: 0.2196078431, alpha: 1)
        
        navigationItem.titleView = setupMainTitleView()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage.image(named: ImageConstants.viewed), style: .plain, target: self, action: #selector(viewedTapped))
        navigationItem.rightBarButtonItem?.tintColor = #colorLiteral(red: 0.1490196078, green: 0.1960784314, blue: 0.2196078431, alpha: 1)
    }
    
    func setupTableView() {
        listTableView.registerNibCell(ListTableViewCell.self)
        listTableView.rowHeight = 100
        listTableView.separatorStyle = .none
        listTableView.dataSource = self
        listTableView.delegate = self
    }
}

extension HereafterViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.numberOfItems() ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let viewModel = viewModel, let cell = tableView.dequeueReusableCell(withIdentifier: "ListTableViewCell", for: indexPath) as? ListTableViewCell else {
            return UITableViewCell()
        }
        cell.tag = indexPath.row
        let movie = viewModel.itemFor(index: indexPath.row)
        if let posterURL = movie.posterImageURL() {
            imageLoader.imageFromUrl(url: posterURL) { image in
                if (cell.tag == indexPath.row) {
                    cell.posterImageView.transition(to: image)
                }
            }
        } else {
            if (cell.tag == indexPath.row) {
                cell.posterImageView.transition(to: UIImage.image(named: ImageConstants.posterholder))
            }
        }
        cell.setup(title: movie.title)
        return cell
    }
}

extension HereafterViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let viewModel = viewModel else { return nil }
        var actions: [UIContextualAction] = []
        for type in viewModel.swipeLeftTypes() {
            let action = UIContextualAction(style: .normal,
                                            title: type.title) { [weak self] (action, view, completionHandler) in
                self?.viewModel?.updateType(index: indexPath.row, type: type)
                completionHandler(true)
            }
            action.backgroundColor = type.typeColor
            actions.append(action)
        }
        return UISwipeActionsConfiguration(actions: actions)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let viewModel = viewModel else { return nil }
        var actions: [UIContextualAction] = []
        for type in viewModel.swipeRightTypes() {
            let action = UIContextualAction(style: .normal,
                                            title: type.title) { [weak self] (action, view, completionHandler) in
                self?.viewModel?.updateType(index: indexPath.row, type: type)
                completionHandler(true)
            }
            action.backgroundColor = type.typeColor
            actions.append(action)
        }
        return UISwipeActionsConfiguration(actions: actions)
    }
}

extension HereafterViewController: HereafterViewProtocol {
    
    func reloadData() {
        listTableView.reloadData()
    }
    
    func updateUI() {
        guard let viewModel = viewModel else { return }
        firstlyView.backgroundColor = viewModel.selectedType == .foremost ? UIColor.foremostColor : .white
        secondlyView.backgroundColor = viewModel.selectedType == .possibly ? UIColor.possiblyColor : .white
        thirdlyView.backgroundColor = viewModel.selectedType == .ifNothingElse ? UIColor.ifNothingElseColor : .white
        switch viewModel.selectedType {
        case .foremost:
            listTableView.backgroundColor = UIColor.foremostColor
        case .possibly:
            listTableView.backgroundColor = UIColor.possiblyColor
        case .ifNothingElse:
            listTableView.backgroundColor = UIColor.ifNothingElseColor
        case .viewed:
            listTableView.backgroundColor = .white
        }
    }
    
    func showError(error: Error) {
        showAlert(title: "Error", message: "\(error.localizedDescription)", actionTitle: nil)
    }
}
