//
//  FirebaseAuthService.swift
//  Hafter
//
//  Requires firebase-ios-sdk via SPM:
//  File → Add Package Dependencies → https://github.com/firebase/firebase-ios-sdk
//  Select: FirebaseAuth, FirebaseFirestore, FirebaseCore
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
    /// Presents Sign in with Apple, reauthenticates the current user, and returns
    /// the one-time Apple authorization code needed to revoke the token.
    func reauthenticateWithApple(from viewController: UIViewController, completion: @escaping (Result<String, Error>) -> Void)
    /// Revokes the Sign in with Apple token, then deletes the Firebase Auth user.
    /// Call this only after Firestore data has been removed, while still signed in.
    func revokeAppleTokenAndDeleteUser(authorizationCode: String, completion: @escaping (Error?) -> Void)
}

// MARK: - Implementation

final class FirebaseAuthService: NSObject {

    static let shared = FirebaseAuthService()

    private var currentNonce: String?
    private var pendingRequest: AppleRequest?
    private var authorizationController: ASAuthorizationController?

    private override init() {}
}

extension FirebaseAuthService: FirebaseAuthServiceProtocol {

    var currentUID: String? { Auth.auth().currentUser?.uid }
    var isSignedIn: Bool { Auth.auth().currentUser != nil }

    func signInWithApple(from viewController: UIViewController, completion: @escaping (Result<String, Error>) -> Void) {
        startAppleRequest(.signIn(completion), from: viewController)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func reauthenticateWithApple(from viewController: UIViewController, completion: @escaping (Result<String, Error>) -> Void) {
        guard Auth.auth().currentUser != nil else {
            completion(.failure(AuthError.notSignedIn))
            return
        }
        startAppleRequest(.reauthenticate(completion), from: viewController)
    }

    func revokeAppleTokenAndDeleteUser(authorizationCode: String, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(AuthError.notSignedIn)
            return
        }

        Auth.auth().revokeToken(withAuthorizationCode: authorizationCode) { error in
            DispatchQueue.main.async {
                if let error {
                    completion(error)
                    return
                }
                user.delete { deleteError in
                    DispatchQueue.main.async {
                        if let deleteError {
                            if AuthError.isRequiresRecentLogin(deleteError) {
                                completion(AuthError.requiresRecentLogin)
                            } else {
                                completion(deleteError)
                            }
                            return
                        }
                        completion(nil)
                    }
                }
            }
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension FirebaseAuthService: ASAuthorizationControllerDelegate {

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        let request = pendingRequest
        pendingRequest = nil
        authorizationController = nil

        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let idTokenData = appleCredential.identityToken,
              let idToken = String(data: idTokenData, encoding: .utf8) else {
            finish(request, with: .failure(AuthError.invalidCredential))
            return
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: nonce,
            fullName: appleCredential.fullName
        )

        switch request {
        case .signIn(let completion):
            Auth.auth().signIn(with: credential) { result, error in
                DispatchQueue.main.async {
                    if let error {
                        completion(.failure(error))
                        return
                    }
                    guard let uid = result?.user.uid else {
                        completion(.failure(AuthError.missingUID))
                        return
                    }
                    completion(.success(uid))
                }
            }

        case .reauthenticate(let completion):
            guard let user = Auth.auth().currentUser else {
                completion(.failure(AuthError.notSignedIn))
                return
            }
            guard let authorizationCodeData = appleCredential.authorizationCode,
                  let authorizationCode = String(data: authorizationCodeData, encoding: .utf8),
                  !authorizationCode.isEmpty else {
                completion(.failure(AuthError.missingAuthorizationCode))
                return
            }
            user.reauthenticate(with: credential) { _, error in
                DispatchQueue.main.async {
                    if let error {
                        if AuthError.isRequiresRecentLogin(error) {
                            completion(.failure(AuthError.requiresRecentLogin))
                        } else {
                            completion(.failure(error))
                        }
                        return
                    }
                    // Identity token was used to reauthenticate. The authorization code
                    // is still unused and is what revokeToken(withAuthorizationCode:) consumes.
                    completion(.success(authorizationCode))
                }
            }

        case nil:
            break
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let request = pendingRequest
        pendingRequest = nil
        authorizationController = nil
        // Sign-in keeps Apple's own error. Account deletion treats a dismissed sheet as a cancel.
        if case .reauthenticate = request, AuthError.isCancellation(error) {
            finish(request, with: .failure(AuthError.cancelled))
        } else {
            finish(request, with: .failure(error))
        }
    }
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case invalidCredential
    case missingUID
    case notSignedIn
    case missingAuthorizationCode
    case missingWindow
    case cancelled
    case requiresRecentLogin
    case nonceGenerationFailed

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid Apple credential."
        case .missingUID:
            return "Could not retrieve user ID."
        case .notSignedIn:
            return "You need to be signed in to delete your account."
        case .missingAuthorizationCode:
            return "Apple did not return a code to revoke Sign in with Apple. Nothing was deleted."
        case .missingWindow:
            return "Could not present the Apple confirmation."
        case .cancelled:
            return "Account deletion was cancelled."
        case .requiresRecentLogin:
            return "For your security, confirm with Apple again to delete your account."
        case .nonceGenerationFailed:
            return "Couldn't start Sign in with Apple. Try again."
        }
    }

    static func isCancellation(_ error: Error) -> Bool {
        if let authError = error as? AuthError, case .cancelled = authError {
            return true
        }
        let nsError = error as NSError
        return nsError.domain == ASAuthorizationError.errorDomain
            && nsError.code == ASAuthorizationError.canceled.rawValue
    }

    static func isRequiresRecentLogin(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == AuthErrorDomain
            && nsError.code == AuthErrorCode.requiresRecentLogin.rawValue
    }
}

// MARK: - Nonce helpers

private extension FirebaseAuthService {

    enum AppleRequest {
        case signIn((Result<String, Error>) -> Void)
        case reauthenticate((Result<String, Error>) -> Void)
    }

    func startAppleRequest(_ request: AppleRequest, from viewController: UIViewController) {
        guard let window = viewController.view.window else {
            finish(request, with: .failure(AuthError.missingWindow))
            return
        }

        guard let nonce = randomNonceString() else {
            finish(request, with: .failure(AuthError.nonceGenerationFailed))
            return
        }
        pendingRequest = request
        currentNonce = nonce

        let provider = ASAuthorizationAppleIDProvider()
        let appleRequest = provider.createRequest()
        appleRequest.requestedScopes = [.fullName, .email]
        appleRequest.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [appleRequest])
        controller.delegate = self
        controller.presentationContextProvider = viewController as? ASAuthorizationControllerPresentationContextProviding
            ?? PresentationContextProvider(window: window)
        authorizationController = controller
        controller.performRequests()
    }

    func finish(_ request: AppleRequest?, with result: Result<String, Error>) {
        switch request {
        case .signIn(let completion), .reauthenticate(let completion):
            completion(result)
        case nil:
            break
        }
    }

    func randomNonceString(length: Int = 32) -> String? {
        guard length > 0 else { return nil }
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        guard errorCode == errSecSuccess else { return nil }
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
