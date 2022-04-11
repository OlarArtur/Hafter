//
//  CustomAlertViewController.swift
//  Hafter
//
//  Created by Artur Olar on 06.04.2022.
//

import UIKit

final class CustomAlertViewController: UIViewController {
    
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var actionsStackView: UIStackView!
    
    private var alertView: UIView?
    private var actions: [CustomAlertAction] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func add<T: AlertViewOutput>(alertView: T, actions: [CustomAlertAction] = []) {
        self.alertView = alertView
        alertView.outputAction = { [weak self] output in
            self?.hide(animated: true)
        }
        self.actions = actions
    }
    
    @IBAction func closeAction(_ sender: UIButton) {
        hide(animated: true)
    }
    
    @objc func tapAction(_ sender: UIButton) {
        hide(animated: true)
        if actions.count > sender.tag {
            actions[sender.tag].handler?()
        }
    }
    
    private func setupUI() {
        
        if !actions.isEmpty {
            for action in actions {
                var config = UIButton.Configuration.filled()
                config.title = action.name
                config.baseBackgroundColor = #colorLiteral(red: 0.2862745098, green: 0.3058823529, blue: 0.3764705882, alpha: 1)
                config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
                let actionButton = UIButton(configuration: config, primaryAction: nil)
                actionButton.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), for: .normal)
                actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
                actionButton.tag = actions.firstIndex { $0.name == action.name } ?? 0
                actionButton.addTarget(self, action: #selector(tapAction(_:)), for: .touchUpInside)
                actionsStackView.addArrangedSubview(actionButton)
            }
            actionsStackView.isHidden = false
            actionsStackView.layer.masksToBounds = true
            actionsStackView.layer.cornerRadius = 14
        }
        
        if let alertView = alertView {
            contentView.addSubview(alertView)
            alertView.translatesAutoresizingMaskIntoConstraints = false
            let topConstraint = alertView.topAnchor.constraint(equalTo: contentView.topAnchor)
            let bottomConstraint = alertView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            let leadingConstraint = alertView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
            let trailingConstraint = alertView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
            NSLayoutConstraint.activate([topConstraint, bottomConstraint, leadingConstraint, trailingConstraint])
        }
    }
}

extension CustomAlertViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentAnimator()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimator()
    }
}

struct CustomAlertAction {
    let name: String
    let handler: (() -> Void)?
}
