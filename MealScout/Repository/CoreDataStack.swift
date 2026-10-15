//
//  Repository.swift
//  MealScout
//
//  Created by CLChou on 2026/9/28.
//


import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()
    let persistentContainer: NSPersistentContainer

    init() {
        // "DataModel" MUST match your .xcdatamodeld file name in Xcode
        persistentContainer = NSPersistentContainer(name: "DataModel")
        
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data: \(error)")
            }
        }
    }

    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    func save() throws {
        if context.hasChanges {
            try context.save()
        }
    }
}
