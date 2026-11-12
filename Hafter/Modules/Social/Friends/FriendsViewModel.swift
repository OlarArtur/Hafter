//
//  FriendsViewModel.swift
//  Hafter
//

import Foundation
import FirebaseFirestore

protocol FriendsViewModelProtocol: AnyObject {
    var currentUser: SocialUser? { get }
    var friends: [SocialUser] { get }
    var pendingSessions: [MovieSession] { get }
    var onUpdate: (() -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }
    func load()
    func addFriend(shareCode: String)
    func onCreateSessionTapped(with friend: SocialUser)
    func onSessionTapped(_ session: MovieSession)
    var onPresentCreateSession: ((SocialUser) -> Void)? { get set }
    var onPresentSession: ((MovieSession) -> Void)? { get set }
}

final class FriendsViewModel {

    var onUpdate: (() -> Void)?
    var onError: ((String) -> Void)?
    var onPresentCreateSession: ((SocialUser) -> Void)?
    var onPresentSession: ((MovieSession) -> Void)?

    private(set) var currentUser: SocialUser?
    private(set) var friends: [SocialUser] = []
    private(set) var pendingSessions: [MovieSession] = []

    private let firestoreService: FirestoreServiceProtocol
    private let uid: String
    private var pendingListener: ListenerRegistration?

    init(uid: String, firestoreService: FirestoreServiceProtocol = FirestoreService.shared) {
        self.uid = uid
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
                self.firestoreService.getSession(id: id) { session in
                    if let session { sessions.append(session) }
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
