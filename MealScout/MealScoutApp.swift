//
//  MealScoutApp.swift
//  MealScout
//
//  Created by CLChou on 2026/9/22.
//

import SwiftUI
import CoreData
import MapKit

@main
struct MealScoutApp: App {
    let persistenceController = PersistenceController.shared
    init() {
        let sharedContext = CoreDataStack.shared.context
        // SeedData.clearData(context: sharedContext)
        SeedData.seedData(context: sharedContext)
        
        print("📁 Database Location: \(FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.path)")
    }
    var body: some Scene {
        WindowGroup {
            MapView()
        }
    }
}
