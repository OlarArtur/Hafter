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
//    session id in `pendingSessions` until they next open Friends; a missing
//    session is dropped from that list.
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
    func getUser(uid: String, completion: @escaping (SocialUser?) -> Void)
    func searchUser(byShareCode code: String, completion: @escaping (SocialUser?) -> Void)
    func addFriend(myUID: String, friendUID: String, completion: @escaping (Error?) -> Void)
    func observePendingSessions(uid: String, handler: @escaping ([String]) -> Void) -> ListenerRegistration
    func deleteAccountData(uid: String, completion: @escaping (Error?) -> Void)

    // Sessions
    func createSession(_ session: MovieSession, completion: @escaping (Error?) -> Void)
    func getSession(id: String, completion: @escaping (MovieSession?, Error?) -> Void)
    func acceptSession(sessionID: String, uid: String, completion: @escaping (Error?) -> Void)
    func declineSession(sessionID: String, uid: String, completion: @escaping (Error?) -> Void)
    func recordVote(sessionID: String, uid: String, movieID: String, vote: String, completion: @escaping (Error?) -> Void)
    func finaliseSession(sessionID: String, result: String?, completion: @escaping (Error?) -> Void)
    func observeSession(id: String, handler: @escaping (MovieSession?) -> Void) -> ListenerRegistration
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

    func getUser(uid: String, completion: @escaping (SocialUser?) -> Void) {
        usersCollection.document(uid).getDocument { snapshot, _ in
            guard let data = snapshot?.data() else { completion(nil); return }
            completion(SocialUser(uid: uid, data: data))
        }
    }

    func searchUser(byShareCode code: String, completion: @escaping (SocialUser?) -> Void) {
        let normalized = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.range(of: "^[A-Z0-9]{6}$", options: .regularExpression) != nil else {
            completion(nil)
            return
        }
        shareCodesCollection.document(normalized).getDocument { snapshot, _ in
            guard let data = snapshot?.data(),
                  let uid = data["uid"] as? String,
                  let displayName = data["displayName"] as? String else {
                completion(nil)
                return
            }
            completion(SocialUser(uid: uid, displayName: displayName, shareCode: normalized))
        }
    }

    func addFriend(myUID: String, friendUID: String, completion: @escaping (Error?) -> Void) {
        let batch = db.batch()
        batch.updateData(["friends": FieldValue.arrayUnion([friendUID])], forDocument: usersCollection.document(myUID))
        batch.updateData(["friends": FieldValue.arrayUnion([myUID])], forDocument: usersCollection.document(friendUID))
        batch.commit { completion($0) }
    }

    func observePendingSessions(uid: String, handler: @escaping ([String]) -> Void) -> ListenerRegistration {
        usersCollection.document(uid).addSnapshotListener { snapshot, _ in
            let ids = snapshot?.data()?["pendingSessions"] as? [String] ?? []
            handler(ids)
        }
    }

    func deleteAccountData(uid: String, completion: @escaping (Error?) -> Void) {
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

    func getSession(id: String, completion: @escaping (MovieSession?, Error?) -> Void) {
        sessionsCollection.document(id).getDocument { snapshot, error in
            if let error {
                completion(nil, error)
                return
            }
            guard let data = snapshot?.data() else {
                completion(nil, nil)
                return
            }
            completion(MovieSession(id: id, data: data), nil)
        }
    }

    func acceptSession(sessionID: String, uid: String, completion: @escaping (Error?) -> Void) {
        let batch = db.batch()
        batch.updateData(["status": SessionStatus.active.rawValue], forDocument: sessionsCollection.document(sessionID))
        batch.updateData(["pendingSessions": FieldValue.arrayRemove([sessionID])], forDocument: usersCollection.document(uid))
        batch.commit { completion($0) }
    }

    func declineSession(sessionID: String, uid: String, completion: @escaping (Error?) -> Void) {
        usersCollection.document(uid).updateData(
            ["pendingSessions": FieldValue.arrayRemove([sessionID])]
        ) { completion($0) }
    }

    func recordVote(sessionID: String, uid: String, movieID: String, vote: String, completion: @escaping (Error?) -> Void) {
        sessionsCollection.document(sessionID).updateData(
            ["votes.\(uid).\(movieID)": vote]
        ) { completion($0) }
    }

    func finaliseSession(sessionID: String, result: String?, completion: @escaping (Error?) -> Void) {
        var update: [String: Any] = ["status": SessionStatus.done.rawValue]
        if let result { update["result"] = result }
        sessionsCollection.document(sessionID).updateData(update) { completion($0) }
    }

    func observeSession(id: String, handler: @escaping (MovieSession?) -> Void) -> ListenerRegistration {
        sessionsCollection.document(id).addSnapshotListener { snapshot, _ in
            guard let data = snapshot?.data() else { handler(nil); return }
            handler(MovieSession(id: id, data: data))
        }
    }
}

// MARK: - Account deletion

private extension FirestoreService {

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
