//
//  HereafterV2ViewController.swift
//  Hafter
//
//  Created by Artur Olar on 05.10.2022.
//

import UIKit

protocol HereafterV2ViewProtocol: AnyObject {
    func reloadData()
    func updateUI()
    func showError(error: Error)
}

final class HereafterV2ViewController: BaseViewController<HereafterViewModelProtocol> {
    
    deinit {
        print("deinit HereafterViewController")
    }
    
    @IBOutlet private weak var addView: UIView!
    @IBOutlet private weak var randomizeView: UIView!
    
    private let imageLoader = ImageLoader()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationController()
        
        let addTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(addAction))
        addView.addGestureRecognizer(addTapGestureRecognizer)
        let randomizeTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(randomizeAction))
        randomizeView.addGestureRecognizer(randomizeTapGestureRecognizer)
        viewModel?.select(type: .foremost)
        
        setupCollectionViews()
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

private extension HereafterV2ViewController {
    
    func setupNavigationController() {
        
//        FUTURE IDEA
//        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage.image(named: ImageConstants.menu), style: .plain, target: self, action: #selector(menuTapped))
//        navigationItem.leftBarButtonItem?.tintColor = #colorLiteral(red: 0.1490196078, green: 0.1960784314, blue: 0.2196078431, alpha: 1)
        
        navigationItem.titleView = setupMainTitleView()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage.image(named: ImageConstants.viewed), style: .plain, target: self, action: #selector(viewedTapped))
        navigationItem.rightBarButtonItem?.tintColor = #colorLiteral(red: 0.1490196078, green: 0.1960784314, blue: 0.2196078431, alpha: 1)
    }
    
    func setupCollectionViews() {
        
    }
    
    func setupCollectionViewFlowLayout() -> UICollectionViewFlowLayout {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        return flowLayout
    }
}

extension HereafterV2ViewController: HereafterViewProtocol {
    
    func reloadData() {
    }
    
    func updateUI() {
        
    }
    
    func showError(error: Error) {
        showAlert(title: "Error", message: "\(error.localizedDescription)", actionTitle: nil)
    }
}
