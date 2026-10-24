//
//  Timeout.swift
//  ScamShield
//
//  Created by student2 on 2026-10-25.
//

import Foundation

//makes sure a waiting caller is woken exactly once, by whichever of two racers finishes first
nonisolated final class OneShot<Value: Sendable>: @unchecked Sendable {

    private let lock = NSLock()
    private var continuation: CheckedContinuation<Value, Never>?

    init(_ continuation: CheckedContinuation<Value, Never>) {
        self.continuation = continuation
    }

    func resume(returning value: Value) {
        lock.lock()
        let pending = continuation
        continuation = nil
        lock.unlock()

        pending?.resume(returning: value)
    }
}

enum Timeout {

    //gives nil when the work is not done in time, a late answer is simply ignored
    //a task group cannot be used because it would still wait for work that never notices it was cancelled
    static func run<Value: Sendable>(
        after seconds: Double,
        _ work: @escaping @Sendable () async -> Value?
    ) async -> Value? {
        await withCheckedContinuation { (continuation: CheckedContinuation<Value?, Never>) in
            let gate = OneShot(continuation)

            Task { gate.resume(returning: await work()) }
            Task {
                try? await Task.sleep(for: .seconds(seconds))
                gate.resume(returning: nil)
            }
        }
    }
}
