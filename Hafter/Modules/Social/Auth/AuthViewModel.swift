//
//  AuthViewModel.swift
//  Hafter
//

import Foundation

protocol AuthViewModelProtocol {
    var onSuccess: ((SocialUser) -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }
    func signInWithApple(from viewController: AuthViewController)
}

final class AuthViewModel {

    var onSuccess: ((SocialUser) -> Void)?
    var onError: ((String) -> Void)?

    private let authService: FirebaseAuthServiceProtocol
    private let firestoreService: FirestoreServiceProtocol

    init(authService: FirebaseAuthServiceProtocol = FirebaseAuthService.shared,
         firestoreService: FirestoreServiceProtocol = FirestoreService.shared) {
        self.authService = authService
        self.firestoreService = firestoreService
    }
}

extension AuthViewModel: AuthViewModelProtocol {

    func signInWithApple(from viewController: AuthViewController) {
        authService.signInWithApple(from: viewController) { [weak self] result in
            switch result {
            case .success(let uid):
                self?.fetchOrCreateUser(uid: uid)
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.onError?(error.localizedDescription)
                }
            }
        }
    }

    private func fetchOrCreateUser(uid: String) {
        firestoreService.getUser(uid: uid) { [weak self] existing in
            if let existing {
                DispatchQueue.main.async { self?.onSuccess?(existing) }
            } else {
                self?.createNewUser(uid: uid)
            }
        }
    }

    private func createNewUser(uid: String) {
        let user = SocialUser(
            uid: uid,
            displayName: "Hafter User",
            shareCode: SocialUser.generateShareCode()
        )
        firestoreService.createUser(user) { [weak self] error in
            DispatchQueue.main.async {
                if let error {
                    self?.onError?(error.localizedDescription)
                } else {
                    self?.onSuccess?(user)
                }
            }
        }
    }
}
