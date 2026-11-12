//
//  AuthViewController.swift
//  Hafter
//

import UIKit
import AuthenticationServices

final class AuthViewController: UIViewController {

    var viewModel: AuthViewModelProtocol?
    var onSignedIn: ((SocialUser) -> Void)?

    // MARK: - Views

    private let gradientLayer: CAGradientLayer = {
        let g = CAGradientLayer()
        g.colors = [DS.Color.accent.cgColor, DS.Color.brandIndigo.cgColor]
        g.startPoint = CGPoint(x: 0, y: 0)
        g.endPoint = CGPoint(x: 1, y: 1)
        return g
    }()

    private let logoLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Hafter"
        l.font = DS.Typography.display
        l.textColor = .white
        return l
    }()

    private let taglineLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Pick movies together with friends"
        l.font = DS.Typography.body
        l.textColor = UIColor.white.withAlphaComponent(0.8)
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private let signInButton: ASAuthorizationAppleIDButton = {
        let b = ASAuthorizationAppleIDButton(type: .signIn, style: .white)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.cornerRadius = DS.Radius.button
        return b
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let a = UIActivityIndicatorView(style: .medium)
        a.translatesAutoresizingMaskIntoConstraints = false
        a.color = .white
        a.hidesWhenStopped = true
        return a
    }()

    private let dismissButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(UIImage(systemName: "xmark"), for: .normal)
        b.tintColor = UIColor.white.withAlphaComponent(0.7)
        return b
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        bindViewModel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }
}

// MARK: - Setup

private extension AuthViewController {

    func setupLayout() {
        view.layer.insertSublayer(gradientLayer, at: 0)
        view.addSubview(dismissButton)
        view.addSubview(logoLabel)
        view.addSubview(taglineLabel)
        view.addSubview(signInButton)
        view.addSubview(activityIndicator)

        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        signInButton.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            dismissButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: DS.Spacing.s),
            dismissButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DS.Spacing.m),
            dismissButton.widthAnchor.constraint(equalToConstant: 32),
            dismissButton.heightAnchor.constraint(equalToConstant: 32),

            logoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -80),

            taglineLabel.topAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: DS.Spacing.s),
            taglineLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DS.Spacing.xl),
            taglineLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DS.Spacing.xl),

            signInButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -DS.Spacing.xl),
            signInButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DS.Spacing.m),
            signInButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DS.Spacing.m),
            signInButton.heightAnchor.constraint(equalToConstant: 50),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.bottomAnchor.constraint(equalTo: signInButton.topAnchor, constant: -DS.Spacing.m)
        ])
    }

    func bindViewModel() {
        viewModel?.onSuccess = { [weak self] user in
            self?.activityIndicator.stopAnimating()
            self?.signInButton.isEnabled = true
            self?.onSignedIn?(user)
            self?.dismiss(animated: true)
        }
        viewModel?.onError = { [weak self] message in
            self?.activityIndicator.stopAnimating()
            self?.signInButton.isEnabled = true
            let alert = UIAlertController(title: "Sign In Failed", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }

    @objc func signInTapped() {
        signInButton.isEnabled = false
        activityIndicator.startAnimating()
        viewModel?.signInWithApple(from: self)
    }

    @objc func dismissTapped() {
        dismiss(animated: true)
    }
}

// MARK: - Presentation context

extension AuthViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        view.window!
    }
}
