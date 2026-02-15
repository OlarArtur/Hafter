//
//  HereAfterMainViewController.swift
//  Hafter
//
//  Created by Artur Olar on 15.11.2023.
//

import UIKit

protocol HereafterViewProtocol: AnyObject {
    func reloadData()
    func updateUI()
    func showError(error: Error)
}

final class HereAfterMainViewController: BaseViewController<HereafterViewModelProtocol> {
    
    @IBOutlet private weak var addView: UIView!
    @IBOutlet private weak var randomizeView: UIView!
    
    @IBOutlet private weak var foremostView: VerticalLabelView!
    @IBOutlet private weak var possiblyView: VerticalLabelView!
    @IBOutlet private weak var ifNothingElseView: VerticalLabelView!
    
    @IBOutlet private weak var listTableView: UITableView!
    
    private let imageLoader = ImageLoader()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        foremostView.text = HereafterMovieType.foremost.title
        possiblyView.text = HereafterMovieType.possibly.title
        ifNothingElseView.text = HereafterMovieType.ifNothingElse.title

        setupNavigationController()
        setupGestures()
        setupTableView()
        
        foremostAction()
    }
    
    @objc private func addAction() {
        viewModel?.add()
    }
    
    @objc private func randomizeAction() {
        viewModel?.randomize()
    }
    
    @objc private func viewedTapped() {
        viewModel?.openViewed()
    }
    
    @objc private func foremostAction() {
        select(type: .foremost)
        viewModel?.select(type: .foremost, rect: .zero)
    }
    
    @objc private func possiblyAction() {
        select(type: .possibly)
        viewModel?.select(type: .possibly, rect: .zero)
    }
    
    @objc private func ifNothingElseAction() {
        select(type: .ifNothingElse)
        viewModel?.select(type: .ifNothingElse, rect: .zero)
    }
}

private extension HereAfterMainViewController {
    
    func setupGestures() {
        
        let addTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(addAction))
        addView.addGestureRecognizer(addTapGestureRecognizer)
        let randomizeTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(randomizeAction))
        randomizeView.addGestureRecognizer(randomizeTapGestureRecognizer)
        
        let foremostTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(foremostAction))
        foremostView.addGestureRecognizer(foremostTapGestureRecognizer)
        
        let possiblyTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(possiblyAction))
        possiblyView.addGestureRecognizer(possiblyTapGestureRecognizer)
        
        let ifNothingElseTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ifNothingElseAction))
        ifNothingElseView.addGestureRecognizer(ifNothingElseTapGestureRecognizer)
    }
    
    func setupTableView() {
        listTableView.registerNibCell(ListTableViewCell.self)
        listTableView.separatorStyle = .none
        listTableView.rowHeight = 140
        listTableView.dataSource = self
        listTableView.delegate = self
    }
    
    func setupNavigationController() {
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage.image(named: ImageConstants.viewed), style: .plain, target: self, action: #selector(viewedTapped))
        navigationItem.rightBarButtonItem?.tintColor = #colorLiteral(red: 0.1490196078, green: 0.1960784314, blue: 0.2196078431, alpha: 1)
    }
    
    func select(type: HereafterMovieType) {
        var foremostIsSelected = false
        var possiblyIsSelected = false
        var ifNothingElseIsSelected = false
        switch type {
        case .foremost:
            foremostIsSelected = true
        case .possibly:
            possiblyIsSelected = true
        case .ifNothingElse:
            ifNothingElseIsSelected = true
        default:
            break
        }
        foremostView.isSelected = foremostIsSelected
        possiblyView.isSelected = possiblyIsSelected
        ifNothingElseView.isSelected = ifNothingElseIsSelected
    }
}

extension HereAfterMainViewController: HereafterViewProtocol {
    
    func reloadData() {
        listTableView.reloadData()
    }
    
    func updateUI() {
        
    }
    
    func showError(error: Error) {
        showAlert(title: "Error", message: "\(error.localizedDescription)", actionTitle: nil)
    }
}

extension HereAfterMainViewController: UITableViewDataSource {
    
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

extension HereAfterMainViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel?.didSelect(index: indexPath.row)
    }
    
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
