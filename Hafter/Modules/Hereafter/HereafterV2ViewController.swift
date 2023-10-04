//
//  HereafterV2ViewController.swift
//  Hafter
//
//  Created by Artur Olar on 05.10.2022.
//

import UIKit

protocol HereafterV2ViewProtocol: AnyObject {
    func updateUI()
    func showError(error: Error)
}

final class HereafterV2ViewController: BaseViewController<HereafterViewModelProtocol> {
    
    deinit {
        print("deinit HereafterViewController")
    }
    
    @IBOutlet private weak var addView: UIView!
    @IBOutlet private weak var randomizeView: UIView!
    
    @IBOutlet private weak var foremostView: UIView!
    @IBOutlet private weak var possiblyView: UIView!
    @IBOutlet private weak var ifNothingElseView: UIView!
    
    private let imageLoader = ImageLoader()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationController()
        
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
    
    @objc private func foremostAction() {
        viewModel?.select(type: .foremost, rect: foremostView.frame)
    }
    
    @objc private func possiblyAction() {
        viewModel?.select(type: .possibly, rect: possiblyView.frame)
    }
    
    @objc private func ifNothingElseAction() {
        viewModel?.select(type: .ifNothingElse, rect: ifNothingElseView.frame)
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
