//
//  HistoryRepository.swift
//  ScamShield
//
//  Created by student2 on 2026-10-23.
//

import CoreData

//protocol so view models do not depend on core data directly
protocol HistoryStoring {
    func save(_ result: ScanResult) throws
    func fetchAll() throws -> [ScanResult]
    func fetchUnsynced() throws -> [ScanResult]
    func markSynced(ids: [UUID]) throws
    func delete(id: UUID) throws
    func deleteAll() throws
}

struct CoreDataHistoryRepository: HistoryStoring {

    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.viewContext) {
        self.context = context
    }

    //updates the record if the same scan is saved again instead of making a duplicate
    func save(_ result: ScanResult) throws {
        let record = try record(with: result.id) ?? ScanRecord(context: context)
        record.id = result.id
        record.type = result.type.rawValue
        record.input = result.input
        record.riskLevel = result.riskLevel.rawValue
        record.trustScore = Int16(result.trustScore)
        record.signalsData = try JSONEncoder().encode(result.signals)
        record.date = result.date
        record.isSynced = false
        try context.save()
    }

    func fetchAll() throws -> [ScanResult] {
        let request = ScanRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ScanRecord.date, ascending: false)]
        return try context.fetch(request).compactMap(\.scanResult)
    }

    func fetchUnsynced() throws -> [ScanResult] {
        let request = ScanRecord.fetchRequest()
        request.predicate = NSPredicate(format: "isSynced == NO")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ScanRecord.date, ascending: true)]
        return try context.fetch(request).compactMap(\.scanResult)
    }

    func markSynced(ids: [UUID]) throws {
        guard !ids.isEmpty else { return }
        let request = ScanRecord.fetchRequest()
        request.predicate = NSPredicate(format: "id IN %@", NSArray(array: ids.map { $0 as NSUUID }))
        try context.fetch(request).forEach { $0.isSynced = true }
        try context.save()
    }

    func delete(id: UUID) throws {
        guard let record = try record(with: id) else { return }
        context.delete(record)
        try context.save()
    }

    func deleteAll() throws {
        try context.fetch(ScanRecord.fetchRequest()).forEach(context.delete)
        try context.save()
    }

    private func record(with id: UUID) throws -> ScanRecord? {
        let request = ScanRecord.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}

extension ScanRecord {

    //converts the stored record back into the app model and skips broken rows
    var scanResult: ScanResult? {
        guard let id, let input, let date,
              let type = type.flatMap(ScanType.init(rawValue:)),
              let riskLevel = riskLevel.flatMap(RiskLevel.init(rawValue:)) else {
            return nil
        }
        let signals = signalsData.flatMap { try? JSONDecoder().decode([RiskSignal].self, from: $0) } ?? []
        return ScanResult(id: id, type: type, input: input, riskLevel: riskLevel, trustScore: Int(trustScore), signals: signals, date: date)
    }
}
