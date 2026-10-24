//
//  NetworkMonitorTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
import Network
@testable import ScamShield

@MainActor
struct NetworkMonitorTests {

    let monitor = NetworkMonitor()
    let reconnects = Counter()

    init() {
        monitor.onReconnect = { [reconnects] in reconnects.count += 1 }
    }

    @Test func startsOutAssumingItIsOnline() {
        #expect(monitor.isOnline)
    }

    @Test(arguments: [
        (NWPath.Status.satisfied, true),
        (NWPath.Status.unsatisfied, false),
        (NWPath.Status.requiresConnection, false)
    ])
    func onlyASatisfiedPathCountsAsOnline(status: NWPath.Status, expected: Bool) {
        monitor.handle(status: status)
        #expect(monitor.isOnline == expected)
    }

    @Test func comingBackOnlineCallsTheHandlerOnce() {
        monitor.handle(status: .unsatisfied)
        monitor.handle(status: .satisfied)
        monitor.handle(status: .satisfied)

        #expect(reconnects.count == 1)
    }

    @Test func eachRecoveryIsReported() {
        for _ in 1...2 {
            monitor.handle(status: .unsatisfied)
            monitor.handle(status: .satisfied)
        }
        #expect(reconnects.count == 2)
    }

    @Test func staysQuietWhileNothingChanges() {
        monitor.handle(status: .satisfied)
        monitor.handle(status: .satisfied)
        #expect(reconnects.count == 0)

        monitor.handle(status: .unsatisfied)
        monitor.handle(status: .unsatisfied)
        #expect(reconnects.count == 0)
    }

    @Test func goingOfflineDoesNotCallTheHandler() {
        monitor.handle(status: .unsatisfied)
        #expect(reconnects.count == 0)
        #expect(!monitor.isOnline)
    }
}

//counts calls from inside a closure
@MainActor
final class Counter {
    var count = 0
}
