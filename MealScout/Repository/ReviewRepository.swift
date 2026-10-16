//
//  ReviewRepository.swift
//  MealScout
//
//  Created by CLChou on 2026/9/28.
//

// File: CoreDataReviewRepository.swift
import CoreData
import FirebaseFirestore

// @MainActor
protocol ReviewRepository {
    func fetchAll() async throws -> [Review]
    func save(_ review: Review) async throws
    func delete(id: UUID) async throws
    func getReviewsForRestaurant(mapIdentifier: MapIdentifier) async throws -> [Review]
}

// @MainActor
final class CoreDataReviewRepository: ReviewRepository {
    
    // Core Data connection and JSON handlers
    private let stack: CoreDataStack
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // Initialize with shared database stack
    init(stack: CoreDataStack = .shared) {
        self.stack = stack
    }

    func fetchAll() throws -> [Review] {
        let request: NSFetchRequest<ReviewEntity> = ReviewEntity.fetchRequest()
        let entities = try stack.context.fetch(request)

        return try entities.compactMap { entity in
            guard let data = entity.reviewData else { return nil }
            return try decoder.decode(Review.self, from: data)
        }
    }

    func save(_ review: Review) throws {
        let request: NSFetchRequest<ReviewEntity> = ReviewEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", review.id as CVarArg)
        
        let entity: ReviewEntity
        if let existingEntity = try stack.context.fetch(request).first {
            entity = existingEntity
        } else {
            entity = ReviewEntity(context: stack.context)
            entity.id = review.id
        }

        entity.reviewData = try encoder.encode(review)

        // Step C: Persist changes to disk
        try? stack.save()
    }

    func delete(id: UUID) throws {
        // Step A: Search for the database row matching this ID
        let request: NSFetchRequest<ReviewEntity> = ReviewEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        // Step B: If found, delete the row and save
        if let entity = try stack.context.fetch(request).first {
            stack.context.delete(entity)
            try stack.save()
        }
    }
    
    func getReviewsForRestaurant(mapIdentifier: MapIdentifier) throws -> [Review] {
        return try fetchAll().filter { $0.restaurant.id == mapIdentifier }
    }
}

final class FirebaseReviewRepository: ReviewRepository {
    private let db = Firestore.firestore()
    private let collectionRef = Firestore.firestore().collection("reviews")
    
    func fetchAll() async throws -> [Review] {
        let snapshot = try await collectionRef
            .order(by: "id")
            .getDocuments()
            
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Review.self)
        }
    }
    
    func save(_ review: Review) async throws {
        try collectionRef
            .document(review.id.uuidString)
            .setData(from: review, merge: true)
    }
    
    func delete(id: UUID) async throws {
        try await collectionRef
            .document(id.uuidString)
            .delete()
    }
    
    func getReviewsForRestaurant(mapIdentifier: MapIdentifier) async throws -> [Review] {
        let snapshot = try await collectionRef
            .whereField("restaurantID", isEqualTo: mapIdentifier)
            .getDocuments()
            
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Review.self)
        }
    }
    
    
}
