//
//  IntroductionViewController.swift
//  Hafter
//
//  Created by Artur Olar on 29.03.2022.
//

import UIKit

protocol IntroductionViewProtocol: AnyObject {
    
}

final class IntroductionViewController: BaseViewController<IntroductionViewModelProtocol> {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func getStartedAction(_ sender: Any) {
        viewModel?.getStarted()
    }
}

extension IntroductionViewController: IntroductionViewProtocol {
    
}
