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
    
    @IBOutlet private weak var addView: UIView!
    @IBOutlet private weak var randomizeView: UIView!
    
    @IBOutlet private weak var firstlyView: UIView!
    @IBOutlet private weak var secondlyView: UIView!
    @IBOutlet private weak var thirdlyView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
    }
    
    @objc private func secondlyAction() {
        
    }
    
    @objc private func thirdlyAction() {
        
    }
    
    @objc private func addAction() {
        
    }
    
    @objc private func randomizeAction() {
        
    }
}

extension HereafterViewController: HereafterViewProtocol {
    
}
