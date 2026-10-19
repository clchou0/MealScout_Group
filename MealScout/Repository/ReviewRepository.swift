//
//  ReviewRepository.swift
//  MealScout
//
//  Created by CLChou on 2026/9/28.
//

// File: CoreDataReviewRepository.swift
import FirebaseFirestore
import MapKit

// @MainActor
protocol ReviewRepository {
    func fetchAll() async throws -> [Review]
    func save(_ review: Review) async throws
    func delete(id: UUID) async throws
    func getReviewsForRestaurant(mapIdentifier: MapIdentifier) async throws -> [Review]
}

// @MainActor
final class FirebaseReviewRepository: ReviewRepository {
    private let db = Firestore.firestore()
    private let collectionRef = Firestore.firestore().collection("reviews")
    
    func fetchAll() async throws -> [Review] {
        let snapshot = try await collectionRef
            .order(by: "id")
            .getDocuments(source: .server)
        
        return try snapshot.documents.compactMap { doc in
            try doc.data(as: Review.self)
        }
    }
    
    func save(_ review: Review) async throws {
        let data = try Firestore.Encoder().encode(review)

        try await collectionRef
            .document(review.id.uuidString)
            .setData(data, merge: true)
    }
    
    func delete(id: UUID) async throws {
        try await collectionRef
            .document(id.uuidString)
            .delete()
    }
    
    func getReviewsForRestaurant(mapIdentifier: MapIdentifier) async throws -> [Review] {
        let snapshot = try await collectionRef
            .whereField("restaurantID", isEqualTo: mapIdentifier.rawValue)
            .getDocuments(source: .server)
        
        return try snapshot.documents.compactMap { doc in
            try doc.data(as: Review.self)
        }
    }
}
