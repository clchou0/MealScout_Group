//
//  FetchRestaurantDetailsUseCase.swift
//  MealScout
//
//  Created by CLChou on 2026/9/29.
//

import Foundation

/// Fetches necessary details for a restaurant

class FetchRestaurantDetailsUseCase {
    private let reviewRepository: ReviewRepository
    private let restaurantRepository: RestaurantRepository
    
    init(reviewRepository: ReviewRepository = CoreDataReviewRepository(),
         restaurantRepository: RestaurantRepository = CoreDataRestaurantRepository()) {
        self.reviewRepository = reviewRepository
        self.restaurantRepository = restaurantRepository
    }
    
    func fetchReviewsFromRestaurant(mapIdentifier: MapIdentifier) async -> [Review] {
        do {
            return try await reviewRepository.getReviewsForRestaurant(mapIdentifier: mapIdentifier)
        } catch {
            print("\(error.localizedDescription)")
        }
        return []
    }
    
    func fetchTagsFromRestaurant(mapIdentifier: MapIdentifier) async -> [CuisineTag] {
        do {
            return try await restaurantRepository.getTagsForRestaurant(id: mapIdentifier)
        }
        catch { print("\(error.localizedDescription)") }
        return []
    }
}
