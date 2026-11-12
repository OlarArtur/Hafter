//
//  FirebaseAuthService.swift
//  Hafter
//
//  Requires firebase-ios-sdk (FirebaseAuth) via SPM:
//  File → Add Package Dependencies → https://github.com/firebase/firebase-ios-sdk
//  Select: FirebaseAuth, FirebaseFirestore
//

import UIKit
import FirebaseAuth
import AuthenticationServices
import CryptoKit

// MARK: - Protocol

protocol FirebaseAuthServiceProtocol {
    var currentUID: String? { get }
    var isSignedIn: Bool { get }
    func signInWithApple(from viewController: UIViewController, completion: @escaping (Result<String, Error>) -> Void)
    func signOut() throws
}

// MARK: - Implementation

final class FirebaseAuthService: NSObject {

    static let shared = FirebaseAuthService()

    private var currentNonce: String?
    private var signInCompletion: ((Result<String, Error>) -> Void)?

    private override init() {}
}

extension FirebaseAuthService: FirebaseAuthServiceProtocol {

    var currentUID: String? { Auth.auth().currentUser?.uid }
    var isSignedIn: Bool { Auth.auth().currentUser != nil }

    func signInWithApple(from viewController: UIViewController, completion: @escaping (Result<String, Error>) -> Void) {
        self.signInCompletion = completion
        let nonce = randomNonceString()
        currentNonce = nonce

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = viewController as? ASAuthorizationControllerPresentationContextProviding
            ?? PresentationContextProvider(window: viewController.view.window!)
        controller.performRequests()
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension FirebaseAuthService: ASAuthorizationControllerDelegate {

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let idTokenData = appleCredential.identityToken,
              let idToken = String(data: idTokenData, encoding: .utf8) else {
            signInCompletion?(.failure(AuthError.invalidCredential))
            return
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: nonce,
            fullName: appleCredential.fullName
        )

        Auth.auth().signIn(with: credential) { [weak self] result, error in
            if let error {
                self?.signInCompletion?(.failure(error))
                return
            }
            guard let uid = result?.user.uid else {
                self?.signInCompletion?(.failure(AuthError.missingUID))
                return
            }
            self?.signInCompletion?(.success(uid))
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        signInCompletion?(.failure(error))
    }
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case invalidCredential
    case missingUID

    var errorDescription: String? {
        switch self {
        case .invalidCredential: return "Invalid Apple credential."
        case .missingUID: return "Could not retrieve user ID."
        }
    }
}

// MARK: - Nonce helpers

private extension FirebaseAuthService {

    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Presentation context helper

private final class PresentationContextProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    private let window: UIWindow
    init(window: UIWindow) { self.window = window }
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor { window }
}
