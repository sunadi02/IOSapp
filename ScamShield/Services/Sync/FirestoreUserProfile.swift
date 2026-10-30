//
//  FirestoreUserProfile.swift
//  ScamShield
//
//  Created by student2 on 2026-10-30.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import os

//stores each signed in user at users/{uid} so the account shows in firestore, scans sit under it
enum FirestoreUserProfile {

    static let log = Logger(subsystem: "sunadi.ScamShield", category: "Firestore")

    //merge keeps createdAt from the first sign in while the rest is refreshed every time
    static func save(_ user: User) async {
        let document = Firestore.firestore().collection("users").document(user.uid)

        do {
            let existing = try await document.getDocument()
            var data: [String: Any] = [
                "email": user.email ?? "",
                "displayName": user.displayName ?? "",
                "lastSignInAt": FieldValue.serverTimestamp()
            ]
            if !existing.exists {
                data["createdAt"] = FieldValue.serverTimestamp()
            }
            try await document.setData(data, merge: true)
        } catch {
            log.error("Saving profile for \(user.uid, privacy: .private) failed: \(error.localizedDescription)")
        }
    }
}
