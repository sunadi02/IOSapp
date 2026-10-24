//
//  IntentServices.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import FirebaseCore

//Siri and Shortcuts can start the app in the background, so cloud features are only used once firebase is ready
enum IntentServices {

    static var isFirebaseReady: Bool {
        FirebaseApp.app() != nil
    }

    static var linkScanner: LinkScanner {
        isFirebaseReady ? .live : LinkScanner()
    }

    static var history: HistoryStoring {
        isFirebaseReady ? AppHistory.store : CoreDataHistoryRepository()
    }
}
