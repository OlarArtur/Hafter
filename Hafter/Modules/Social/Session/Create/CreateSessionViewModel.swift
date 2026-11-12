//
//  CreateSessionViewModel.swift
//  Hafter
//

import Foundation

protocol CreateSessionViewModelProtocol: AnyObject {
    var friend: SocialUser { get }
    var selectedMode: SessionMode { get set }
    var selectedList: HereafterMovieType { get set }
    var onSessionCreated: ((MovieSession) -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }
    func createSession()
}

final class CreateSessionViewModel {

    let friend: SocialUser
    var selectedMode: SessionMode = .swipe
    var selectedList: HereafterMovieType = .foremost
    var onSessionCreated: ((MovieSession) -> Void)?
    var onError: ((String) -> Void)?

    private let uid: String
    private let localService: LocalServiceProtocol
    private let firestoreService: FirestoreServiceProtocol

    init(uid: String,
         friend: SocialUser,
         localService: LocalServiceProtocol,
         firestoreService: FirestoreServiceProtocol = FirestoreService.shared) {
        self.uid = uid
        self.friend = friend
        self.localService = localService
        self.firestoreService = firestoreService
    }
}

extension CreateSessionViewModel: CreateSessionViewModelProtocol {

    func createSession() {
        let tagged = localService
            .getMovies(type: selectedList)
            .map { hm in
                SessionMovie(
                    id: hm.movie.id,
                    title: hm.movie.title,
                    posterPath: hm.movie.posterPath,
                    year: hm.movie.year(),
                    contributors: [uid]
                )
            }

        guard !tagged.isEmpty else {
            onError?("Your \(selectedList.title) list is empty. Add some movies first.")
            return
        }

        let session = MovieSession(
            id: UUID().uuidString,
            createdBy: uid,
            participants: [uid, friend.uid],
            status: .pending,
            mode: selectedMode,
            sourceList: selectedList.rawValue,
            movies: tagged,
            contributions: [uid: selectedList.rawValue]
        )

        firestoreService.createSession(session) { [weak self] error in
            DispatchQueue.main.async {
                if let error {
                    let message: String
                    if SocialErrorMessage.isOffline(error) {
                        message = "Couldn't create the session. Check your connection and try again."
                    } else if SocialErrorMessage.isNotFound(error) {
                        message = "That friend is no longer available."
                    } else {
                        message = error.localizedDescription
                    }
                    self?.onError?(message)
                } else {
                    self?.onSessionCreated?(session)
                }
            }
        }
    }
}
