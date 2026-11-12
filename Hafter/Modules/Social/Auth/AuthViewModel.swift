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
        firestoreService.getUser(uid: uid) { [weak self] result in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.onError?(SocialErrorMessage.userVisible(
                        error,
                        offline: "Couldn't sign in. Check your connection and try again."
                    ))
                }
            case .success(let existing?):
                self?.firestoreService.registerShareCode(
                    uid: existing.uid,
                    displayName: existing.displayName,
                    shareCode: existing.shareCode
                ) { _ in
                    DispatchQueue.main.async { self?.onSuccess?(existing) }
                }
            case .success(nil):
                self?.createNewUser(uid: uid)
            }
        }
    }

    private func createNewUser(uid: String, attempts: Int = 0) {
        let user = SocialUser(
            uid: uid,
            displayName: "Hafter User",
            shareCode: SocialUser.generateShareCode()
        )
        firestoreService.createUser(user) { [weak self] error in
            if let error {
                if attempts < 4, SocialDataError.isShareCodeTaken(error) {
                    self?.createNewUser(uid: uid, attempts: attempts + 1)
                    return
                }
                DispatchQueue.main.async {
                    self?.onError?(SocialErrorMessage.userVisible(
                        error,
                        offline: "Couldn't create your profile. Check your connection and try again."
                    ))
                }
                return
            }
            DispatchQueue.main.async {
                self?.onSuccess?(user)
            }
        }
    }
}
