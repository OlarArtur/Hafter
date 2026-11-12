//
//  SocialUser.swift
//  Hafter
//

import Foundation

struct SocialUser {
    let uid: String
    var displayName: String
    var shareCode: String
    var friendUIDs: [String]
    var pendingSessionIDs: [String]

    init(uid: String, displayName: String, shareCode: String, friendUIDs: [String] = [], pendingSessionIDs: [String] = []) {
        self.uid = uid
        self.displayName = displayName
        self.shareCode = shareCode
        self.friendUIDs = friendUIDs
        self.pendingSessionIDs = pendingSessionIDs
    }

    init?(uid: String, data: [String: Any]) {
        guard let displayName = data["displayName"] as? String,
              let shareCode = data["shareCode"] as? String else { return nil }
        self.uid = uid
        self.displayName = displayName
        self.shareCode = shareCode
        self.friendUIDs = data["friends"] as? [String] ?? []
        self.pendingSessionIDs = data["pendingSessions"] as? [String] ?? []
    }

    var firestoreData: [String: Any] {
        [
            "displayName": displayName,
            "shareCode": shareCode,
            "friends": friendUIDs,
            "pendingSessions": pendingSessionIDs
        ]
    }

    static func generateShareCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}
