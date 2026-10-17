//
//  RestaurantRepository.swift
//  MealScout
//
//  Created by CLChou on 2026/9/28.
//

import Foundation
import CoreData
import MapKit
import FirebaseFirestore
// @MainActor
protocol RestaurantRepository {
    func fetchAll() async throws -> [Restaurant]
    func save(_ restaurant: Restaurant) async throws
    func delete(id: MapIdentifier) async throws
    func find(by id: MapIdentifier) async throws -> Restaurant?
    
    func findOrCreateRestaurant(id: MapIdentifier, restaurantName: String, lat: Double, lng: Double) async throws -> Restaurant
    func getTagsForRestaurant(id: MapIdentifier) async throws -> [CuisineTag]
}

// @MainActor
final class CoreDataRestaurantRepository: RestaurantRepository {
    private let stack: CoreDataStack
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(stack: CoreDataStack = .shared) {
        self.stack = stack
    }
    
    func fetchAll() throws -> [Restaurant] {
        let request: NSFetchRequest<RestaurantEntity> = RestaurantEntity.fetchRequest()
        let entities: [RestaurantEntity] = try stack.context.fetch(request)
        
        return try entities.compactMap { entity in
            guard let data = entity.restaurantData else { return nil }
            return try decoder.decode(Restaurant.self, from: data)
        }
    }
    
    func save(_ restaurant: Restaurant) throws {
        let request: NSFetchRequest<RestaurantEntity> = RestaurantEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", restaurant.id.rawValue)
        
        let entity: RestaurantEntity
        if let existingEntity = try stack.context.fetch(request).first {
            entity = existingEntity
        } else {
            entity = RestaurantEntity(context: stack.context)
            entity.id = restaurant.id.rawValue
        }
        
        entity.restaurantData = try encoder.encode(restaurant)
        try stack.save()
    }

    func delete(id: MapIdentifier) throws {
        let request: NSFetchRequest<RestaurantEntity> = RestaurantEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id.rawValue)

        if let entity = try stack.context.fetch(request).first {
            stack.context.delete(entity)
            try stack.save()
        }
    }
    
    func find(by id: MapIdentifier) throws -> Restaurant? {
        let request: NSFetchRequest<RestaurantEntity> = RestaurantEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id.rawValue)
        
        guard let entity = try stack.context.fetch(request).first,
              let data = entity.restaurantData else { return nil }
        
        return try? decoder.decode(Restaurant.self, from: data)
    }
    
    func findOrCreateRestaurant(id: MapIdentifier, restaurantName: String, lat: Double, lng: Double) throws -> Restaurant {
        if var existing = try find(by: id) {
            print("Restaurant exists")
            existing.name = restaurantName
            existing.latitude = lat
            existing.longitude = lng
            try save(existing)
            return existing
        } else {
            print("Restaurant \(id.rawValue) added")
            let newRestaurant = Restaurant(id: id, name: restaurantName, tags: [], latitude: lat, longitude: lng)
            try save(newRestaurant)
            return newRestaurant
        }
    }
    
    func getTagsForRestaurant(id: MapIdentifier) throws -> [CuisineTag] {
        if let restaurant = try find(by: id) {
            return restaurant.tags
        } else { return [] }
    }
}

final class FirebaseRestaurantRepository: RestaurantRepository {
    private let db = Firestore.firestore()
    private let collectionRef = Firestore.firestore().collection("restaurants")
    
    func fetchAll() async throws -> [Restaurant] {
        let snapshot = try await collectionRef.getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Restaurant.self)
        }
    }
    
    func save(_ restaurant: Restaurant) async throws {
        try collectionRef
            .document(restaurant.id.rawValue)
            .setData(from: restaurant, merge: true)
    }
    
    func delete(id: MapIdentifier) async throws {
        try await collectionRef
            .document(id.rawValue)
            .delete()
    }
    
    func find(by id: MapIdentifier) async throws -> Restaurant? {
        let document = try await collectionRef
            .document(id.rawValue)
            .getDocument()
        
        guard document.exists else { return nil }
        return try? document.data(as: Restaurant.self)
    }
    
    func findOrCreateRestaurant(id: MapIdentifier, restaurantName: String, lat: Double, lng: Double) async throws -> Restaurant
    {
        if var existing = try await find(by: id) {
            print("Restaurant exists in Firestore: \(restaurantName)")
            existing.name = restaurantName
            try await save(existing)
            return existing
        } else {
            print("Restaurant \(id.rawValue) added to Firestore")
            let newRestaurant = Restaurant(id: id, name: restaurantName, tags: [], latitude: lat, longitude: lng)
            try await save(newRestaurant)
            return newRestaurant
        }
    }
    
    func getTagsForRestaurant(id: MapIdentifier) async throws -> [CuisineTag] {
        if let restaurant = try await find(by: id) {
            return restaurant.tags
        } else {
            return []
        }
    }
    
    
}

