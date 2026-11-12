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
    private var userListener: ListenerRegistration?
    private var isDeleting = false
    private var friendFetchGeneration = 0
    private var pendingFetchGeneration = 0
    private var displayedFriendUIDs: [String] = []
    private var displayedPendingIDs: [String] = []
    private var lastError: String?

    init(uid: String,
         authService: FirebaseAuthServiceProtocol = FirebaseAuthService.shared,
         firestoreService: FirestoreServiceProtocol = FirestoreService.shared) {
        self.uid = uid
        self.authService = authService
        self.firestoreService = firestoreService
    }

    deinit { userListener?.remove() }
}

extension FriendsViewModel: FriendsViewModelProtocol {

    func load() {
        guard isDeleting == false else { return }
        startObserving()
    }

    func addFriend(shareCode: String) {
        let code = shareCode.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        firestoreService.searchUser(byShareCode: code) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                self.report(SocialErrorMessage.userVisible(
                    error,
                    offline: "Couldn't look up that code. Check your connection and try again."
                ))
            case .success(nil):
                self.report("No user found with code \(code)")
            case .success(let found?):
                guard found.uid != self.uid else {
                    self.report("That's your own code!")
                    return
                }
                self.firestoreService.addFriend(myUID: self.uid, friendUID: found.uid) { error in
                    if let error {
                        self.report(SocialErrorMessage.userVisible(
                            error,
                            offline: "Couldn't add that friend. Check your connection and try again."
                        ))
                    } else if self.friends.contains(where: { $0.uid == found.uid }) == false {
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
        userListener?.remove()
        userListener = nil

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
                        self.userListener?.remove()
                        self.userListener = nil
                        self.isDeleting = false
                        self.onDeletingChanged?(false)
                        self.onAccountDeleted?()
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

    private func report(_ message: String) {
        guard message != lastError else { return }
        lastError = message
        onError?(message)
    }

    private func startObserving() {
        userListener?.remove()
        userListener = nil
        lastError = nil
        displayedFriendUIDs = []
        displayedPendingIDs = []
        userListener = firestoreService.observeUser(uid: uid) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                self.report(SocialErrorMessage.userVisible(
                    error,
                    offline: "Couldn't refresh friends. Check your connection and try again."
                ))
            case .success(nil):
                self.report("Your profile is no longer available.")
                self.onAccountDeleted?()
            case .success(let user?):
                self.lastError = nil
                self.currentUser = user
                self.onUpdate?()
                if user.friendUIDs != self.displayedFriendUIDs {
                    self.displayedFriendUIDs = user.friendUIDs
                    self.loadFriends(uids: user.friendUIDs)
                }
                if user.pendingSessionIDs != self.displayedPendingIDs {
                    self.displayedPendingIDs = user.pendingSessionIDs
                    self.loadPending(ids: user.pendingSessionIDs)
                }
            }
        }
    }

    private func loadFriends(uids: [String]) {
        friendFetchGeneration += 1
        let generation = friendFetchGeneration
        guard uids.isEmpty == false else {
            friends = []
            onUpdate?()
            return
        }
        var slots = Array<SocialUser?>(repeating: nil, count: uids.count)
        var missing: [String] = []
        var sawOffline = false
        let group = DispatchGroup()
        for (index, friendUID) in uids.enumerated() {
            group.enter()
            firestoreService.getUser(uid: friendUID) { [weak self] result in
                defer { group.leave() }
                guard let self else { return }
                switch result {
                case .success(let user?):
                    slots[index] = user
                case .success(nil):
                    missing.append(friendUID)
                case .failure(let error):
                    if SocialErrorMessage.isStale(error) {
                        missing.append(friendUID)
                    } else {
                        sawOffline = true
                        slots[index] = self.friends.first { $0.uid == friendUID }
                    }
                }
            }
        }
        group.notify(queue: .main) { [weak self] in
            guard let self, self.friendFetchGeneration == generation else { return }
            self.friends = slots.compactMap { $0 }
            self.onUpdate?()
            if sawOffline {
                self.report("Couldn't refresh some friends. Check your connection and try again.")
            }
            for friendUID in missing {
                self.firestoreService.removeStaleFriend(myUID: self.uid, friendUID: friendUID) { _ in }
            }
        }
    }

    private func loadPending(ids: [String]) {
        pendingFetchGeneration += 1
        let generation = pendingFetchGeneration
        guard ids.isEmpty == false else {
            pendingSessions = []
            onUpdate?()
            return
        }
        var sessions = Array<MovieSession?>(repeating: nil, count: ids.count)
        var dropIDs: [String] = []
        var leaveIDs: [String] = []
        var sawOffline = false
        let group = DispatchGroup()
        for (index, id) in ids.enumerated() {
            group.enter()
            firestoreService.getSession(id: id) { [weak self] session, error in
                defer { group.leave() }
                guard let self else { return }
                if let session {
                    if session.isExpiredPendingInvite {
                        leaveIDs.append(id)
                    } else if session.isStaleDoneInvite {
                        dropIDs.append(id)
                    } else {
                        sessions[index] = session
                    }
                } else if let error, SocialErrorMessage.isStale(error) == false {
                    sawOffline = true
                    sessions[index] = self.pendingSessions.first { $0.id == id }
                } else {
                    dropIDs.append(id)
                }
            }
        }
        group.notify(queue: .main) { [weak self] in
            guard let self, self.pendingFetchGeneration == generation else { return }
            self.pendingSessions = sessions.compactMap { $0 }
            self.onUpdate?()
            if sawOffline {
                self.report("Couldn't refresh invitations. Check your connection and try again.")
            }
            for id in dropIDs {
                self.firestoreService.removePendingInvite(sessionID: id, uid: self.uid) { _ in }
            }
            for id in leaveIDs {
                self.firestoreService.declineSession(sessionID: id, uid: self.uid) { error in
                    guard let error, SocialErrorMessage.isStale(error) == false else { return }
                    self.report(SocialErrorMessage.userVisible(
                        error,
                        offline: "Couldn't update an old invitation. Check your connection and try again."
                    ))
                }
            }
        }
    }

    private func finishDeletion(error: Error) {
        isDeleting = false
        onDeletingChanged?(false)
        if authService.isSignedIn {
            startObserving()
        }
        if AuthError.isCancellation(error) { return }
        report(SocialErrorMessage.userVisible(
            error,
            offline: "Couldn't delete your account. Check your connection and try again."
        ))
    }
}
