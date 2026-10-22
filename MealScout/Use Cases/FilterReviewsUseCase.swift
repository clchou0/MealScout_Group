//
//  FilterReviewsUseCase.swift
//  MealScout
//
//  Created by CLChou on 2026/10/6.
//

import Foundation
import MapKit
/// Filter all the reviews against the object and returns restaurants that match

class FilterReviewsUseCase {
    private let reviewRepository: ReviewRepository
    private let restaurantRepository: RestaurantRepository
    
    init(reviewRepository: ReviewRepository = FirebaseReviewRepository(),
         restaurantRepository: RestaurantRepository = FirebaseRestaurantRepository()) {
        self.reviewRepository = reviewRepository
        self.restaurantRepository = restaurantRepository
    }
    
    func execute(filter: FilterObject,
        targetLocation: CLLocationCoordinate2D) async -> Result<[Restaurant], Error> {
        let allReviews: [Review]
        
        do {
            allReviews = try await fetchAllReviews()
        } catch {
            return .failure(error)
        }
        
        var candidateRestaurants: [Restaurant] = []
        var seenIDs: Set<Restaurant.ID> = []
        
        for review in allReviews where filter.evaluate(review: review) {
            if seenIDs.insert(review.restaurant.id).inserted {
                candidateRestaurants.append(review.restaurant)
            }
        }
        
        let validRestaurants = candidateRestaurants.filter { restaurant in
            let from = CLLocation(latitude: targetLocation.latitude, longitude: targetLocation.longitude)
            let to = CLLocation(latitude: restaurant.latitude, longitude: restaurant.longitude)
            return from.distance(from: to) <= 1000
        }
        return .success(validRestaurants)
    }
    
    func fetchAllReviews() async throws -> [Review] {
        return try await reviewRepository.fetchAll()
    }
}
