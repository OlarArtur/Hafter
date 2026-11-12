//
//  FirestoreService.swift
//  Hafter
//

import Foundation
import FirebaseFirestore

// MARK: - Protocol

protocol FirestoreServiceProtocol {
    // Users
    func createUser(_ user: SocialUser, completion: @escaping (Error?) -> Void)
    func getUser(uid: String, completion: @escaping (SocialUser?) -> Void)
    func searchUser(byShareCode code: String, completion: @escaping (SocialUser?) -> Void)
    func addFriend(myUID: String, friendUID: String, completion: @escaping (Error?) -> Void)
    func observePendingSessions(uid: String, handler: @escaping ([String]) -> Void) -> ListenerRegistration

    // Sessions
    func createSession(_ session: MovieSession, completion: @escaping (Error?) -> Void)
    func getSession(id: String, completion: @escaping (MovieSession?) -> Void)
    func acceptSession(sessionID: String, uid: String, completion: @escaping (Error?) -> Void)
    func declineSession(sessionID: String, uid: String, completion: @escaping (Error?) -> Void)
    func recordVote(sessionID: String, uid: String, movieID: String, vote: String, completion: @escaping (Error?) -> Void)
    func finaliseSession(sessionID: String, result: String?, completion: @escaping (Error?) -> Void)
    func observeSession(id: String, handler: @escaping (MovieSession?) -> Void) -> ListenerRegistration
}

// MARK: - Implementation

final class FirestoreService {

    static let shared = FirestoreService()

    private let db = Firestore.firestore()
    private var usersCollection: CollectionReference { db.collection("users") }
    private var sessionsCollection: CollectionReference { db.collection("sessions") }

    private init() {}
}

extension FirestoreService: FirestoreServiceProtocol {

    // MARK: Users

    func createUser(_ user: SocialUser, completion: @escaping (Error?) -> Void) {
        usersCollection.document(user.uid).setData(user.firestoreData, merge: true) { error in
            completion(error)
        }
    }

    func getUser(uid: String, completion: @escaping (SocialUser?) -> Void) {
        usersCollection.document(uid).getDocument { snapshot, _ in
            guard let data = snapshot?.data() else { completion(nil); return }
            completion(SocialUser(uid: uid, data: data))
        }
    }

    func searchUser(byShareCode code: String, completion: @escaping (SocialUser?) -> Void) {
        usersCollection
            .whereField("shareCode", isEqualTo: code.uppercased())
            .limit(to: 1)
            .getDocuments { snapshot, _ in
                guard let doc = snapshot?.documents.first else { completion(nil); return }
                completion(SocialUser(uid: doc.documentID, data: doc.data()))
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

    func getSession(id: String, completion: @escaping (MovieSession?) -> Void) {
        sessionsCollection.document(id).getDocument { snapshot, _ in
            guard let data = snapshot?.data() else { completion(nil); return }
            completion(MovieSession(id: id, data: data))
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
