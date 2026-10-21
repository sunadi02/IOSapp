//
//  ScanType.swift
//  ScamShield
//
//  Created by student2 on 2026-10-21.
//

import Foundation

enum ScanType: String, Codable, CaseIterable {
    case link
    case qr
    case screenshot
}
