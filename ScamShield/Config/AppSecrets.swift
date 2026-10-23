//
//  AppSecrets.swift
//  ScamShield
//
//  Created by student2 on 2026-10-23.
//

import Foundation

//reads api keys from secrets.plist which is kept out of git
enum AppSecrets {

    static func value(for key: String, bundle: Bundle = .main) -> String? {
        guard let url = bundle.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return nil
        }
        return dict[key] as? String
    }
}
