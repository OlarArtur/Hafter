//
//  HereafterViewController.swift
//  Hafter
//
//  Created by Artur Olar on 29.03.2022.
//

import UIKit

protocol HereafterViewProtocol: AnyObject {
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationController()
        
        let addTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(addAction))
        addView.addGestureRecognizer(addTapGestureRecognizer)
        let randomizeTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(randomizeAction))
        randomizeView.addGestureRecognizer(randomizeTapGestureRecognizer)
        
        let firstlyTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(firstlyAction))
        firstlyView.addGestureRecognizer(firstlyTapGestureRecognizer)
        let secondlyTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(secondlyAction))
        secondlyView.addGestureRecognizer(secondlyTapGestureRecognizer)
        let thirdlyTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(thirdlyAction))
        thirdlyView.addGestureRecognizer(thirdlyTapGestureRecognizer)
    }
    
    
    @objc private func firstlyAction() {
        viewModel?.openList(type: .foremost)
    }
    
    @objc private func secondlyAction() {
        viewModel?.openList(type: .possibly)
    }
    
    @objc private func thirdlyAction() {
        viewModel?.openList(type: .ifNothingElse)
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
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage.image(named: ImageConstants.menu), style: .plain, target: self, action: #selector(menuTapped))
        navigationItem.leftBarButtonItem?.tintColor = #colorLiteral(red: 0.1490196078, green: 0.1960784314, blue: 0.2196078431, alpha: 1)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage.image(named: ImageConstants.viewed), style: .plain, target: self, action: #selector(viewedTapped))
        navigationItem.rightBarButtonItem?.tintColor = #colorLiteral(red: 0.1490196078, green: 0.1960784314, blue: 0.2196078431, alpha: 1)
    }
}

extension HereafterViewController: HereafterViewProtocol {
    
}
