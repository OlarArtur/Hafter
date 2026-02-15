//
//  CustomAlertViewController.swift
//  Hafter
//
//  Created by Artur Olar on 06.04.2022.
//

import UIKit

final class CustomAlertViewController: UIViewController {

    private let containerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(red: 0.95, green: 0.97, blue: 0.99, alpha: 1)
        v.layer.cornerRadius = 20
        return v
    }()

    private let contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .clear
        return v
    }()

    private let actionsStackView: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.distribution = .fillEqually
        s.spacing = 1
        s.isHidden = true
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let mainStackView: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.distribution = .equalSpacing
        s.alignment = .center
        s.spacing = 18
        s.translatesAutoresizingMaskIntoConstraints = false
        s.backgroundColor = .clear
        return s
    }()

    private let closeButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(UIImage(named: "close"), for: .normal)
        return b
    }()

    private var alertView: UIView?
    private var actions: [CustomAlertAction] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.8)
        setupLayout()
        closeButton.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        setupUI()
    }

    func add<T: AlertViewOutput>(alertView: T, actions: [CustomAlertAction] = []) {
        self.alertView = alertView
        alertView.outputAction = { [weak self] _ in
            self?.hide(animated: true)
        }
        self.actions = actions
    }

    @objc private func closeAction() {
        hide(animated: true)
    }

    @objc private func tapAction(_ sender: UIButton) {
        hide(animated: true)
        if actions.count > sender.tag {
            actions[sender.tag].handler?()
        }
    }

    private func setupLayout() {
        view.addSubview(containerView)
        containerView.addSubview(closeButton)
        containerView.addSubview(mainStackView)
        mainStackView.addArrangedSubview(contentView)
        mainStackView.addArrangedSubview(actionsStackView)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 38),
            containerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -38),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),

            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            closeButton.widthAnchor.constraint(equalToConstant: 25),
            closeButton.heightAnchor.constraint(equalToConstant: 25),

            mainStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            mainStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 46),
            mainStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -9),

            actionsStackView.heightAnchor.constraint(equalToConstant: 44)
        ])
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
                actionButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
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
            NSLayoutConstraint.activate([
                alertView.topAnchor.constraint(equalTo: contentView.topAnchor),
                alertView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                alertView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                alertView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
            ])
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
