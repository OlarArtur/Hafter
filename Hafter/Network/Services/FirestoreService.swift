//
//  FirestoreService.swift
//  Hafter
//
//  Account deletion semantics (see also firestore.rules):
//
//  - users/{uid} is deleted.
//  - shareCodes/{code} is deleted, so the share code stops resolving.
//  - Each friend's `friends` array has this uid removed.
//  - Sessions this user created are deleted. Invitees may still list the
//    session id in `pendingSessions` until they next open Friends; a missing,
//    declined, or week-old pending session is dropped from that list.
//    Declining also removes this uid from the session, so the creator is not
//    left waiting on a vote that will never arrive.
//  - Sessions this user joined but did not create are kept. The uid is removed
//    from `participants` and `votes.{uid}` is deleted. Remaining people continue.
//    If the user was the only other participant, the creator remains.
//  - The on-device watchlist is not account data and is not deleted.
//

import Foundation
import FirebaseFirestore

// MARK: - Protocol

protocol FirestoreServiceProtocol {
    // Users
    func createUser(_ user: SocialUser, completion: @escaping (Error?) -> Void)
    func registerShareCode(uid: String, displayName: String, shareCode: String, completion: @escaping (Error?) -> Void)
    func getUser(uid: String, completion: @escaping (Result<SocialUser?, Error>) -> Void)
    func searchUser(byShareCode code: String, completion: @escaping (Result<SocialUser?, Error>) -> Void)
    func addFriend(myUID: String, friendUID: String, completion: @escaping (Error?) -> Void)
    /// Drops a uid whose user document is gone or no longer readable. Only this
    /// user's `friends` array is changed. The other profile is not written.
    func removeStaleFriend(myUID: String, friendUID: String, completion: @escaping (Error?) -> Void)
    func observeUser(uid: String, handler: @escaping (Result<SocialUser?, Error>) -> Void) -> ListenerRegistration
    func deleteAccountData(uid: String, completion: @escaping (Error?) -> Void)

    // Sessions
    func createSession(_ session: MovieSession, completion: @escaping (Error?) -> Void)
    func contributeMovies(sessionID: String, uid: String, listName: String, movies: [SessionMovie], completion: @escaping (Result<MovieSession, Error>) -> Void)
    func startSession(sessionID: String, completion: @escaping (Error?) -> Void)
    func getSession(id: String, completion: @escaping (MovieSession?, Error?) -> Void)
    func acceptSession(sessionID: String, uid: String, completion: @escaping (Error?) -> Void)
    /// Leaves the session and drops the invite. A missing session still drops the invite.
    func declineSession(sessionID: String, uid: String, completion: @escaping (Error?) -> Void)
    /// Drops the invite without leaving the session. Used once a done or active
    /// session has been opened, and when the session document is already gone.
    func removePendingInvite(sessionID: String, uid: String, completion: @escaping (Error?) -> Void)
    func recordVote(sessionID: String, uid: String, movieID: String, vote: String, completion: @escaping (Error?) -> Void)
    func finaliseSession(sessionID: String, result: String?, completion: @escaping (Error?) -> Void)
    func markWatched(sessionID: String, uid: String, completion: @escaping (Error?) -> Void)
    func observeSession(id: String, handler: @escaping (Result<MovieSession?, Error>) -> Void) -> ListenerRegistration
}

enum SocialErrorMessage {
    static func isOffline(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == FirestoreErrorDomain {
            return nsError.code == FirestoreErrorCode.unavailable.rawValue
                || nsError.code == FirestoreErrorCode.deadlineExceeded.rawValue
                || nsError.code == FirestoreErrorCode.cancelled.rawValue
        }
        return nsError.domain == NSURLErrorDomain
    }

    /// The document is gone, or rules no longer let this user read it.
    /// A network failure is not stale.
    static func isStale(_ error: Error) -> Bool {
        let nsError = error as NSError
        guard nsError.domain == FirestoreErrorDomain else { return false }
        return nsError.code == FirestoreErrorCode.notFound.rawValue
            || nsError.code == FirestoreErrorCode.permissionDenied.rawValue
    }

    static func isNotFound(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == FirestoreErrorDomain
            && nsError.code == FirestoreErrorCode.notFound.rawValue
    }

    static func userVisible(_ error: Error, offline: String) -> String {
        if isOffline(error) { return offline }
        return error.localizedDescription
    }
}

enum SocialDataError: LocalizedError {
    case shareCodeTaken

    static let domain = "Hafter.SocialData"
    static let shareCodeTakenCode = 1

    var errorDescription: String? {
        switch self {
        case .shareCodeTaken:
            return "That share code was just taken. Please try signing in again."
        }
    }

    static func isShareCodeTaken(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == domain && nsError.code == shareCodeTakenCode {
            return true
        }
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? Error, isShareCodeTaken(underlying) {
            return true
        }
        return false
    }
}

// MARK: - Implementation

final class FirestoreService {

    static let shared = FirestoreService()

    private let db = Firestore.firestore()
    private var usersCollection: CollectionReference { db.collection("users") }
    private var sessionsCollection: CollectionReference { db.collection("sessions") }
    private var shareCodesCollection: CollectionReference { db.collection("shareCodes") }

    private init() {}
}

extension FirestoreService: FirestoreServiceProtocol {

    // MARK: Users

    func createUser(_ user: SocialUser, completion: @escaping (Error?) -> Void) {
        let completion = onMain(completion)
        let code = user.shareCode.uppercased()
        let userRef = usersCollection.document(user.uid)
        let codeRef = shareCodesCollection.document(code)

        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let existing: DocumentSnapshot
            do {
                existing = try transaction.getDocument(codeRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            if existing.exists {
                let owner = existing.data()?["uid"] as? String
                if owner != user.uid {
                    errorPointer?.pointee = NSError(
                        domain: SocialDataError.domain,
                        code: SocialDataError.shareCodeTakenCode,
                        userInfo: [NSLocalizedDescriptionKey: SocialDataError.shareCodeTaken.localizedDescription]
                    )
                    return nil
                }
            }

            transaction.setData(user.firestoreData, forDocument: userRef, merge: true)
            transaction.setData(
                ["uid": user.uid, "displayName": user.displayName],
                forDocument: codeRef
            )
            return nil
        }, completion: { _, error in
            completion(error)
        })
    }

    func registerShareCode(uid: String, displayName: String, shareCode: String, completion: @escaping (Error?) -> Void) {
        let completion = onMain(completion)
        let code = shareCode.uppercased()
        guard code.range(of: "^[A-Z0-9]{6}$", options: .regularExpression) != nil else {
            completion(nil)
            return
        }
        let ref = shareCodesCollection.document(code)
        ref.getDocument { snapshot, error in
            if let error {
                completion(error)
                return
            }
            if snapshot?.exists == true {
                completion(nil)
                return
            }
            ref.setData(["uid": uid, "displayName": displayName]) { completion($0) }
        }
    }

    func getUser(uid: String, completion: @escaping (Result<SocialUser?, Error>) -> Void) {
        let completion = onMain(completion)
        usersCollection.document(uid).getDocument { snapshot, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let data = snapshot?.data(), let user = SocialUser(uid: uid, data: data) else {
                completion(.success(nil))
                return
            }
            completion(.success(user))
        }
    }

    func searchUser(byShareCode code: String, completion: @escaping (Result<SocialUser?, Error>) -> Void) {
        let completion = onMain(completion)
        let normalized = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.range(of: "^[A-Z0-9]{6}$", options: .regularExpression) != nil else {
            completion(.success(nil))
            return
        }
        shareCodesCollection.document(normalized).getDocument { snapshot, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let data = snapshot?.data(),
                  let uid = data["uid"] as? String,
                  let displayName = data["displayName"] as? String else {
                completion(.success(nil))
                return
            }
            completion(.success(SocialUser(uid: uid, displayName: displayName, shareCode: normalized)))
        }
    }

    func addFriend(myUID: String, friendUID: String, completion: @escaping (Error?) -> Void) {
        let completion = onMain(completion)
        let batch = db.batch()
        batch.updateData(["friends": FieldValue.arrayUnion([friendUID])], forDocument: usersCollection.document(myUID))
        batch.updateData(["friends": FieldValue.arrayUnion([myUID])], forDocument: usersCollection.document(friendUID))
        batch.commit { completion($0) }
    }

    func removeStaleFriend(myUID: String, friendUID: String, completion: @escaping (Error?) -> Void) {
        let completion = onMain(completion)
        usersCollection.document(myUID).updateData(
            ["friends": FieldValue.arrayRemove([friendUID])]
        ) { completion($0) }
    }

    func observeUser(uid: String, handler: @escaping (Result<SocialUser?, Error>) -> Void) -> ListenerRegistration {
        let handler = onMain(handler)
        return usersCollection.document(uid).addSnapshotListener { snapshot, error in
            if let error {
                handler(.failure(error))
                return
            }
            guard let data = snapshot?.data(), let user = SocialUser(uid: uid, data: data) else {
                handler(.success(nil))
                return
            }
            handler(.success(user))
        }
    }

    func deleteAccountData(uid: String, completion: @escaping (Error?) -> Void) {
        let completion = onMain(completion)
        usersCollection.document(uid).getDocument { [weak self] snapshot, error in
            guard let self else {
                completion(nil)
                return
            }
            if let error {
                completion(error)
                return
            }
            let data = snapshot?.data() ?? [:]
            let friendUIDs = (data["friends"] as? [String] ?? []).filter { $0 != uid }
            let shareCode = (data["shareCode"] as? String)?.uppercased()
            self.fetchSessions(uid: uid) { result in
                switch result {
                case .failure(let error):
                    completion(error)
                case .success(let documents):
                    self.applyAccountDeletion(
                        uid: uid,
                        friendUIDs: friendUIDs,
                        shareCode: shareCode,
                        sessions: documents,
                        completion: completion
                    )
                }
            }
        }
    }

    // MARK: Sessions

    func createSession(_ session: MovieSession, completion: @escaping (Error?) -> Void) {
        let completion = onMain(completion)
        let ref = sessionsCollection.document(session.id)
        let batch = db.batch()
        batch.setData(session.firestoreData, forDocument: ref)
        for uid in session.participants where uid != session.createdBy {
            batch.updateData(
                ["pendingSessions": FieldValue.arrayUnion([session.id])],
                forDocument: usersCollection.document(uid)
            )
        }
        batch.commit { completion($0) }
    }

    func contributeMovies(sessionID: String, uid: String, listName: String, movies: [SessionMovie], completion: @escaping (Result<MovieSession, Error>) -> Void) {
        let completion = onMain(completion)
        let ref = sessionsCollection.document(sessionID)
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(ref)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            guard let data = snapshot.data(), var session = MovieSession(id: sessionID, data: data) else {
                errorPointer?.pointee = NSError(
                    domain: SocialDataError.domain,
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "This session could not be read."]
                )
                return nil
            }
            let incoming = movies.map {
                SessionPool.Incoming(id: $0.id, title: $0.title, posterPath: $0.posterPath, year: $0.year)
            }
            session.movies = SessionPool.merge(session.movies, incoming: incoming, uid: uid)
            session.contributions[uid] = listName
            transaction.updateData([
                "movies": session.movies.map { $0.firestoreData },
                "contributions": session.contributions
            ], forDocument: ref)
            return nil
        }, completion: { [weak self] _, error in
            if let error {
                completion(.failure(error))
                return
            }
            self?.getSession(id: sessionID) { session, readError in
                if let session {
                    completion(.success(session))
                } else {
                    completion(.failure(readError ?? NSError(
                        domain: SocialDataError.domain,
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "This session could not be read."]
                    )))
                }
            }
        })
    }

    func startSession(sessionID: String, completion: @escaping (Error?) -> Void) {
        let completion = onMain(completion)
        sessionsCollection.document(sessionID).updateData([
            "status": SessionStatus.active.rawValue
        ]) { completion($0) }
    }

    func getSession(id: String, completion: @escaping (MovieSession?, Error?) -> Void) {
        sessionsCollection.document(id).getDocument { snapshot, error in
            let session: MovieSession?
            let failure: Error?
            if let error {
                session = nil
                failure = error
            } else if let data = snapshot?.data() {
                session = MovieSession(id: id, data: data)
                failure = nil
            } else {
                session = nil
                failure = nil
            }
            if Thread.isMainThread {
                completion(session, failure)
            } else {
                DispatchQueue.main.async {
                    completion(session, failure)
                }
            }
        }
    }

    func acceptSession(sessionID: String, uid: String, completion: @escaping (Error?) -> Void) {
        let completion = onMain(completion)
        let batch = db.batch()
        batch.updateData(["status": SessionStatus.active.rawValue], forDocument: sessionsCollection.document(sessionID))
        batch.updateData(["pendingSessions": FieldValue.arrayRemove([sessionID])], forDocument: usersCollection.document(uid))
        batch.commit { completion($0) }
    }

    func declineSession(sessionID: String, uid: String, completion: @escaping (Error?) -> Void) {
        let completion = onMain(completion)
        sessionsCollection.document(sessionID).updateData([
            "participants": FieldValue.arrayRemove([uid]),
            "votes.\(uid)": FieldValue.delete()
        ]) { error in
            // notFound: the session was deleted. permissionDenied: this uid is
            // already gone from participants. Either way the invite should go.
            // A network error leaves the invite so it can be retried.
            let canClearInvite = error == nil || Self.isNotFound(error) || Self.isPermissionDenied(error)
            guard canClearInvite else {
                completion(error)
                return
            }
            self.removePendingInvite(sessionID: sessionID, uid: uid, completion: completion)
        }
    }

    func removePendingInvite(sessionID: String, uid: String, completion: @escaping (Error?) -> Void) {
        let completion = onMain(completion)
        usersCollection.document(uid).updateData(
            ["pendingSessions": FieldValue.arrayRemove([sessionID])]
        ) { completion($0) }
    }

    func recordVote(sessionID: String, uid: String, movieID: String, vote: String, completion: @escaping (Error?) -> Void) {
        let completion = onMain(completion)
        sessionsCollection.document(sessionID).updateData(
            ["votes.\(uid).\(movieID)": vote]
        ) { completion($0) }
    }

    func finaliseSession(sessionID: String, result: String?, completion: @escaping (Error?) -> Void) {
        let completion = onMain(completion)
        let ref = sessionsCollection.document(sessionID)
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(ref)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            // The other participant may have already picked a result. Do not
            // overwrite it with a second random choice.
            if snapshot.data()?["status"] as? String == SessionStatus.done.rawValue {
                return nil
            }
            var update: [String: Any] = ["status": SessionStatus.done.rawValue]
            if let result { update["result"] = result }
            transaction.updateData(update, forDocument: ref)
            return nil
        }, completion: { _, error in
            completion(error)
        })
    }

    func markWatched(sessionID: String, uid: String, completion: @escaping (Error?) -> Void) {
        let completion = onMain(completion)
        sessionsCollection.document(sessionID).updateData([
            "watchedBy": FieldValue.arrayUnion([uid])
        ]) { completion($0) }
    }

    func observeSession(id: String, handler: @escaping (Result<MovieSession?, Error>) -> Void) -> ListenerRegistration {
        let handler = onMain(handler)
        return sessionsCollection.document(id).addSnapshotListener { snapshot, error in
            if let error {
                handler(.failure(error))
                return
            }
            guard let data = snapshot?.data() else {
                handler(.success(nil))
                return
            }
            guard let session = MovieSession(id: id, data: data) else {
                handler(.failure(NSError(
                    domain: SocialDataError.domain,
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "This session could not be read."]
                )))
                return
            }
            handler(.success(session))
        }
    }
}

// MARK: - Account deletion

private extension FirestoreService {

    func onMain<T>(_ completion: @escaping (T) -> Void) -> (T) -> Void {
        return { value in
            if Thread.isMainThread {
                completion(value)
            } else {
                DispatchQueue.main.async {
                    completion(value)
                }
            }
        }
    }

    static func isNotFound(_ error: Error?) -> Bool {
        guard let error else { return false }
        let nsError = error as NSError
        return nsError.domain == FirestoreErrorDomain && nsError.code == FirestoreErrorCode.notFound.rawValue
    }

    static func isPermissionDenied(_ error: Error?) -> Bool {
        guard let error else { return false }
        let nsError = error as NSError
        return nsError.domain == FirestoreErrorDomain && nsError.code == FirestoreErrorCode.permissionDenied.rawValue
    }

    func fetchSessions(uid: String, completion: @escaping (Result<[QueryDocumentSnapshot], Error>) -> Void) {
        let group = DispatchGroup()
        let box = SessionBox()

        group.enter()
        sessionsCollection.whereField("participants", arrayContains: uid).getDocuments { snapshot, error in
            box.record(snapshot: snapshot, error: error)
            group.leave()
        }
        group.enter()
        sessionsCollection.whereField("createdBy", isEqualTo: uid).getDocuments { snapshot, error in
            box.record(snapshot: snapshot, error: error)
            group.leave()
        }
        group.notify(queue: .main) {
            if let error = box.error {
                completion(.failure(error))
            } else {
                completion(.success(Array(box.documents.values)))
            }
        }
    }

    func applyAccountDeletion(uid: String,
                              friendUIDs: [String],
                              shareCode: String?,
                              sessions: [QueryDocumentSnapshot],
                              completion: @escaping (Error?) -> Void) {
        var ownedSessionRefs: [DocumentReference] = []
        var leaveUpdates: [(DocumentReference, [String: Any])] = []

        for document in sessions {
            let createdBy = document.data()["createdBy"] as? String
            if createdBy == uid {
                ownedSessionRefs.append(document.reference)
                // Invitees keep the session id in pendingSessions. Rules do not let
                // the creator remove another user's invites. Friends drops the id
                // the next time that session document is missing.
            } else {
                leaveUpdates.append((
                    document.reference,
                    [
                        "participants": FieldValue.arrayRemove([uid]),
                        "votes.\(uid)": FieldValue.delete()
                    ]
                ))
            }
        }

        var operations: [(@escaping (Error?) -> Void) -> Void] = []

        for friendUID in friendUIDs {
            let ref = usersCollection.document(friendUID)
            operations.append { done in
                ref.updateData(["friends": FieldValue.arrayRemove([uid])]) { error in
                    done(Self.ignoringMissingDocument(error))
                }
            }
        }

        for (ref, fields) in leaveUpdates {
            operations.append { done in
                ref.updateData(fields) { error in
                    done(Self.ignoringMissingDocument(error))
                }
            }
        }

        run(operations) { [weak self] error in
            guard let self else {
                completion(error)
                return
            }
            if let error {
                completion(error)
                return
            }
            self.deleteOwnedSessions(ownedSessionRefs, shareCode: shareCode) { error in
                if let error {
                    completion(error)
                    return
                }
                self.usersCollection.document(uid).delete { error in
                    completion(Self.ignoringMissingDocument(error))
                }
            }
        }
    }

    func deleteOwnedSessions(_ refs: [DocumentReference], shareCode: String?, completion: @escaping (Error?) -> Void) {
        var operations: [(@escaping (Error?) -> Void) -> Void] = refs.map { ref in
            { done in
                ref.delete { error in
                    done(Self.ignoringMissingDocument(error))
                }
            }
        }
        if let shareCode, shareCode.range(of: "^[A-Z0-9]{6}$", options: .regularExpression) != nil {
            let ref = shareCodesCollection.document(shareCode)
            operations.append { done in
                ref.delete { error in
                    done(Self.ignoringMissingDocument(error))
                }
            }
        }
        run(operations, completion: completion)
    }

    func run(_ operations: [(@escaping (Error?) -> Void) -> Void], completion: @escaping (Error?) -> Void) {
        guard !operations.isEmpty else {
            completion(nil)
            return
        }
        let group = DispatchGroup()
        let errors = ErrorBox()
        for operation in operations {
            group.enter()
            operation { error in
                if let error { errors.record(error) }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            completion(errors.error)
        }
    }

    static func ignoringMissingDocument(_ error: Error?) -> Error? {
        guard let error = error as NSError? else { return nil }
        if error.domain == FirestoreErrorDomain && error.code == FirestoreErrorCode.notFound.rawValue {
            return nil
        }
        return error
    }
}

private final class SessionBox {
    private let lock = NSLock()
    private(set) var documents: [String: QueryDocumentSnapshot] = [:]
    private(set) var error: Error?

    func record(snapshot: QuerySnapshot?, error: Error?) {
        lock.lock()
        defer { lock.unlock() }
        if let error, self.error == nil { self.error = error }
        for document in snapshot?.documents ?? [] {
            documents[document.documentID] = document
        }
    }
}

private final class ErrorBox {
    private let lock = NSLock()
    private(set) var error: Error?

    func record(_ error: Error) {
        lock.lock()
        if self.error == nil { self.error = error }
        lock.unlock()
    }
}
