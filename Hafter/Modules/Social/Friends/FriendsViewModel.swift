//
//  FriendsViewModel.swift
//  Hafter
//

import UIKit
import FirebaseFirestore

protocol FriendsViewModelProtocol: AnyObject {
    var currentUser: SocialUser? { get }
    var friends: [SocialUser] { get }
    var pendingSessions: [MovieSession] { get }
    var onUpdate: (() -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }
    var onAccountDeleted: (() -> Void)? { get set }
    var onDeletingChanged: ((Bool) -> Void)? { get set }
    func load()
    func addFriend(shareCode: String)
    func deleteAccount(from presenter: UIViewController)
    func onCreateSessionTapped(with friend: SocialUser)
    func onSessionTapped(_ session: MovieSession)
    var onPresentCreateSession: ((SocialUser) -> Void)? { get set }
    var onPresentSession: ((MovieSession) -> Void)? { get set }
}

final class FriendsViewModel {

    var onUpdate: (() -> Void)?
    var onError: ((String) -> Void)?
    var onAccountDeleted: (() -> Void)?
    var onDeletingChanged: ((Bool) -> Void)?
    var onPresentCreateSession: ((SocialUser) -> Void)?
    var onPresentSession: ((MovieSession) -> Void)?

    private(set) var currentUser: SocialUser?
    private(set) var friends: [SocialUser] = []
    private(set) var pendingSessions: [MovieSession] = []

    private let authService: FirebaseAuthServiceProtocol
    private let firestoreService: FirestoreServiceProtocol
    private let uid: String
    private var pendingListener: ListenerRegistration?
    private var isDeleting = false

    init(uid: String,
         authService: FirebaseAuthServiceProtocol = FirebaseAuthService.shared,
         firestoreService: FirestoreServiceProtocol = FirestoreService.shared) {
        self.uid = uid
        self.authService = authService
        self.firestoreService = firestoreService
    }

    deinit { pendingListener?.remove() }
}

extension FriendsViewModel: FriendsViewModelProtocol {

    func load() {
        firestoreService.getUser(uid: uid) { [weak self] user in
            guard let self, let user else { return }
            self.currentUser = user
            self.loadFriends(uids: user.friendUIDs)
            self.observePending()
        }
    }

    func addFriend(shareCode: String) {
        let code = shareCode.uppercased().trimmingCharacters(in: .whitespaces)
        firestoreService.searchUser(byShareCode: code) { [weak self] found in
            guard let self else { return }
            guard let found else {
                DispatchQueue.main.async { self.onError?("No user found with code \(code)") }
                return
            }
            guard found.uid != self.uid else {
                DispatchQueue.main.async { self.onError?("That's your own code!") }
                return
            }
            self.firestoreService.addFriend(myUID: self.uid, friendUID: found.uid) { error in
                DispatchQueue.main.async {
                    if let error {
                        self.onError?(error.localizedDescription)
                    } else {
                        self.friends.append(found)
                        self.onUpdate?()
                    }
                }
            }
        }
    }

    func deleteAccount(from presenter: UIViewController) {
        guard !isDeleting else { return }
        isDeleting = true
        onDeletingChanged?(true)
        pendingListener?.remove()
        pendingListener = nil

        authService.reauthenticateWithApple(from: presenter) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                self.finishDeletion(error: error)
            case .success(let authorizationCode):
                self.firestoreService.deleteAccountData(uid: self.uid) { error in
                    if let error {
                        self.finishDeletion(error: error)
                        return
                    }
                    self.authService.revokeAppleTokenAndDeleteUser(authorizationCode: authorizationCode) { error in
                        if let error {
                            self.finishDeletion(error: error)
                            return
                        }
                        AccountLocalState.clearAfterAccountDeletion()
                        DispatchQueue.main.async {
                            self.isDeleting = false
                            self.onDeletingChanged?(false)
                            self.onAccountDeleted?()
                        }
                    }
                }
            }
        }
    }

    func onCreateSessionTapped(with friend: SocialUser) {
        onPresentCreateSession?(friend)
    }

    func onSessionTapped(_ session: MovieSession) {
        onPresentSession?(session)
    }

    // MARK: Private

    private func loadFriends(uids: [String]) {
        guard !uids.isEmpty else { DispatchQueue.main.async { self.onUpdate?() }; return }
        var loaded: [SocialUser] = []
        let group = DispatchGroup()
        for uid in uids {
            group.enter()
            firestoreService.getUser(uid: uid) { user in
                if let user { loaded.append(user) }
                group.leave()
            }
        }
        group.notify(queue: .main) { [weak self] in
            self?.friends = loaded
            self?.onUpdate?()
        }
    }

    private func finishDeletion(error: Error) {
        DispatchQueue.main.async {
            self.isDeleting = false
            self.onDeletingChanged?(false)
            if self.authService.isSignedIn {
                self.observePending()
            }
            if AuthError.isCancellation(error) { return }
            self.onError?(error.localizedDescription)
        }
    }

    /// Missing sessions and permission-denied reads are stale invites.
    /// Transient network failures keep the invite so it can be retried.
    private func shouldDropPendingSession(_ error: Error?) -> Bool {
        guard let error = error as NSError? else { return true }
        guard error.domain == FirestoreErrorDomain else { return false }
        return error.code == FirestoreErrorCode.notFound.rawValue
            || error.code == FirestoreErrorCode.permissionDenied.rawValue
    }

    private func observePending() {
        pendingListener = firestoreService.observePendingSessions(uid: uid) { [weak self] ids in
            guard let self, !ids.isEmpty else {
                DispatchQueue.main.async { self?.pendingSessions = []; self?.onUpdate?() }
                return
            }
            var sessions: [MovieSession] = []
            let group = DispatchGroup()
            for id in ids {
                group.enter()
                self.firestoreService.getSession(id: id) { session, error in
                    if let session {
                        sessions.append(session)
                    } else if self.shouldDropPendingSession(error) {
                        // Owner deleted the session, or this user can no longer read it.
                        self.firestoreService.declineSession(sessionID: id, uid: self.uid) { _ in }
                    }
                    group.leave()
                }
            }
            group.notify(queue: .main) { [weak self] in
                self?.pendingSessions = sessions
                self?.onUpdate?()
            }
        }
    }
}
