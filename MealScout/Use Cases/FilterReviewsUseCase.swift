//
//  FilterReviewsUseCase.swift
//  MealScout
//
//  Created by CLChou on 2026/10/6.
//

import Foundation

/// Filter all the reviews against the object and returns restaurants that match

class FilterReviewsUseCase {
    private let reviewRepository: ReviewRepository
    private let restaurantRepository: RestaurantRepository
    
    init(reviewRepository: ReviewRepository = CoreDataReviewRepository(),
         restaurantRepository: RestaurantRepository = CoreDataRestaurantRepository()) {
        self.reviewRepository = reviewRepository
        self.restaurantRepository = restaurantRepository
    }
    
    func execute(filter: FilterObject) async -> Result<[Restaurant], Error> {
        var filteredRestaurants: [Restaurant] = []
        let allReviews: [Review]
        do {
            allReviews = try await fetchAllReviews()
        } catch {
            return .failure(error)
        }
        
        for review in allReviews {
            if !filteredRestaurants.contains(where: { review.restaurant.id == $0.id})
                    && filter.evaluate(review: review) {
                filteredRestaurants.append(review.restaurant)
            }
        }
        return .success(filteredRestaurants)
    }
    
    func fetchAllReviews() async throws -> [Review] {
        return try await reviewRepository.fetchAll()
    }
}
