//
//  SocialCoordinator.swift
//  Hafter
//
//  Entry point for the entire Social feature.
//  Presented modally from HereAfterMainViewController.
//

import UIKit

final class SocialCoordinator {

    private weak var presenter: UIViewController?
    private let localService: LocalServiceProtocol
    private let authService: FirebaseAuthServiceProtocol
    private let firestoreService: FirestoreServiceProtocol

    init(presenter: UIViewController,
         localService: LocalServiceProtocol,
         authService: FirebaseAuthServiceProtocol = FirebaseAuthService.shared,
         firestoreService: FirestoreServiceProtocol = FirestoreService.shared) {
        self.presenter = presenter
        self.localService = localService
        self.authService = authService
        self.firestoreService = firestoreService
    }

    /// Call this to launch the Social flow
    func start() {
        if authService.isSignedIn, let uid = authService.currentUID {
            showFriends(uid: uid)
        } else {
            showAuth()
        }
    }

    // MARK: - Auth

    private func showAuth() {
        let authVC = AuthViewController()
        let vm = AuthViewModel(authService: authService, firestoreService: firestoreService)
        authVC.viewModel = vm
        authVC.onSignedIn = { [weak self] user in
            self?.showFriends(uid: user.uid)
        }
        authVC.modalPresentationStyle = .fullScreen
        presenter?.present(authVC, animated: true)
    }

    // MARK: - Friends

    private func showFriends(uid: String) {
        let friendsVC = FriendsViewController()
        let vm = FriendsViewModel(uid: uid, firestoreService: firestoreService)
        friendsVC.viewModel = vm

        vm.onPresentCreateSession = { [weak self] friend in
            self?.showCreateSession(uid: uid, friend: friend, from: friendsVC)
        }
        vm.onPresentSession = { [weak self] session in
            self?.routeToSession(session, uid: uid, from: friendsVC)
        }

        let nav = UINavigationController(rootViewController: friendsVC)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        presenter?.present(nav, animated: true)
    }

    // MARK: - Create session

    private func showCreateSession(uid: String, friend: SocialUser, from presenter: UIViewController) {
        let vc = CreateSessionViewController()
        let vm = CreateSessionViewModel(uid: uid, friend: friend, localService: localService, firestoreService: firestoreService)
        vc.viewModel = vm
        vm.onSessionCreated = { [weak self] session in
            // Creator skips the Join screen and goes straight to the session
            self?.routeCreatorToSession(session, uid: uid, from: presenter)
        }
        let nav = UINavigationController(rootViewController: vc)
        presenter.present(nav, animated: true)
    }

    /// Routes the session creator directly to the correct screen, bypassing Join.
    private func routeCreatorToSession(_ session: MovieSession, uid: String, from presenter: UIViewController) {
        switch session.mode {
        case .swipe:
            showSwipeSession(session, uid: uid, from: presenter)
        case .vote:
            showVoteSession(session, uid: uid, from: presenter)
        case .random:
            showResult(session, from: presenter)
        }
    }

    // MARK: - Route to correct session screen

    private func routeToSession(_ session: MovieSession, uid: String, from presenter: UIViewController) {
        switch session.status {
        case .pending:
            showJoinSession(session, uid: uid, from: presenter)
        case .active:
            switch session.mode {
            case .swipe:  showSwipeSession(session, uid: uid, from: presenter)
            case .vote:   showVoteSession(session, uid: uid, from: presenter)
            case .random: showResult(session, from: presenter)
            }
        case .done:
            showResult(session, from: presenter)
        }
    }

    // MARK: - Join

    private func showJoinSession(_ session: MovieSession, uid: String, from presenter: UIViewController) {
        let vc = JoinSessionViewController()
        vc.session = session
        vc.uid = uid
        vc.onJoined = { [weak self] joined in
            self?.routeToSession(joined, uid: uid, from: presenter)
        }
        vc.modalPresentationStyle = .pageSheet
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        presenter.present(vc, animated: true)
    }

    // MARK: - Swipe

    private func showSwipeSession(_ session: MovieSession, uid: String, from presenter: UIViewController) {
        let vc = SwipeSessionViewController()
        vc.session = session
        vc.uid = uid
        vc.onFinished = { [weak self] finished in
            presenter.dismiss(animated: true) {
                self?.showResult(finished, from: presenter)
            }
        }
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        presenter.present(nav, animated: true)
    }

    // MARK: - Vote

    private func showVoteSession(_ session: MovieSession, uid: String, from presenter: UIViewController) {
        let vc = VoteSessionViewController()
        vc.session = session
        vc.uid = uid
        vc.onFinished = { [weak self] finished in
            presenter.dismiss(animated: true) {
                self?.showResult(finished, from: presenter)
            }
        }
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        presenter.present(nav, animated: true)
    }

    // MARK: - Result

    private func showResult(_ session: MovieSession, from presenter: UIViewController) {
        let vc = SessionResultViewController()
        vc.session = session
        vc.modalPresentationStyle = .fullScreen
        presenter.present(vc, animated: true)
    }
}
