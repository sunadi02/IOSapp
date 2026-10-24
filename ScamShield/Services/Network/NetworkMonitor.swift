//
//  NetworkMonitor.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation
import Network
import Observation

//watches the connection so the app can say when it is offline and catch up when it comes back
@Observable
final class NetworkMonitor {

    private(set) var isOnline = true

    //called once each time the connection returns after being lost
    @ObservationIgnored var onReconnect: (() -> Void)?

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.scamshield.network")
    @ObservationIgnored private var isStarted = false

    init(monitor: NWPathMonitor = NWPathMonitor()) {
        self.monitor = monitor
    }

    func start() {
        guard !isStarted else { return }
        isStarted = true

        monitor.pathUpdateHandler = { [weak self] path in
            let status = path.status
            Task { @MainActor in self?.handle(status: status) }
        }
        monitor.start(queue: queue)
    }

    func handle(status: NWPath.Status) {
        let wasOffline = !isOnline
        isOnline = status == .satisfied

        if isOnline && wasOffline {
            onReconnect?()
        }
    }
}
