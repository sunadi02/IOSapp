//
//  ReportViewModel.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation
import Observation

@Observable
final class ReportViewModel {

    enum State: Equatable {
        case idle
        case sending
        case sent
        case failed(String)
    }

    var category: ScamCategory = .other
    private(set) var state: State = .idle

    let scan: ScanResult
    private let service: CommunityReporting

    init(scan: ScanResult, service: CommunityReporting = FirestoreCommunityService()) {
        self.scan = scan
        self.service = service
    }

    var canSend: Bool {
        state != .sending && state != .sent
    }

    func send() async {
        guard canSend else { return }
        state = .sending

        do {
            try await service.submit(url: scan.input, category: category, type: scan.type)
            state = .sent
        } catch {
            let known = (error as? CommunityError) ?? .unavailable
            state = .failed(known.localizedDescription)
        }
    }
}
