//
//  PersistenceController.swift
//  ScamShield
//
//  Created by student2 on 2026-10-23.
//

import CoreData

//owns the core data stack used for offline scan history
final class PersistenceController {

    static let shared = PersistenceController()

    //model is loaded once so several containers in tests do not clash
    static let model: NSManagedObjectModel = {
        guard let url = Bundle.main.url(forResource: "ScamShield", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: url) else {
            fatalError("ScamShield core data model is missing from the app bundle")
        }
        return model
    }()

    let container: NSPersistentContainer
    private(set) var loadError: Error?

    var viewContext: NSManagedObjectContext { container.viewContext }

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ScamShield", managedObjectModel: Self.model)

        //dev null gives a fresh throwaway store for previews and tests
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { [weak self] _, error in
            self?.loadError = error
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
