//
//  RestaurantRepository.swift
//  MealScout
//
//  Created by CLChou on 2026/9/28.
//

import Foundation
import MapKit
import FirebaseAuth
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
final class FirebaseRestaurantRepository: RestaurantRepository {
    private var collection: CollectionReference {
        Firestore.firestore().collection("restaurants")
    }
    
    func fetchAll() async throws -> [Restaurant] {
        let snapshot = try await collection.getDocuments(source: .server)
        
        return try snapshot.documents.map {
            try $0.data(as: Restaurant.self)
        }
    }
    
    func save(_ restaurant: Restaurant) async throws {
        let data = try Firestore.Encoder().encode(restaurant)
        
        try await collection
            .document(restaurant.id.rawValue)
            .setData(data)
    }
    
    func delete(id: MapIdentifier) async throws {
        try await collection.document(id.rawValue).delete()
    }
    
    func find(by id: MapIdentifier) async throws -> Restaurant? {
        let snapshot = try await collection
            .document(id.rawValue)
            .getDocument(source: .server)
        
        guard snapshot.exists else {
            return nil
        }
        
        return try snapshot.data(as: Restaurant.self)
    }
    
    func findOrCreateRestaurant(id: MapIdentifier, restaurantName: String, lat: Double, lng: Double) async throws -> Restaurant {
        if let existing = try await find(by: id) {
            return existing
        }
        
        let restaurant = Restaurant(
            id: id,
            name: restaurantName,
            tags: [],
            latitude: lat,
            longitude: lng
        )
        
        try await save(restaurant)
        
        return restaurant
    }
    
    func getTagsForRestaurant(
        id: MapIdentifier
    ) async throws -> [CuisineTag] {
        guard let restaurant = try await find(by: id) else {
            return []
        }
        
        return restaurant.tags
    }
}
