//
//  LogReviewUseCase.swift
//  MealScout
//
//  Created by CLChou on 2026/9/26.
//

import Foundation
import FirebaseAuth

/// Logging reviews that 

enum LogReviewError: Equatable, LocalizedError {
    case authenticationRequired
    case invalidMealOccasion
    case dishesEmpty
    case invalidDish
    case invalidPrice
    case invalidDeal
    case invalidDiners
    case emptyReview
    case mapKeyError
    case databaseError
    
    var errorDescription: String? {
        switch self {
        case .authenticationRequired: "Please log in before submitting a review"
        case .invalidMealOccasion: "Please enter when you had the meal"
        case .dishesEmpty: "Please enter at least one dish you had for the meal"
        case .invalidDish: "Please enter corect details for the dishes"
        case .invalidPrice: "Please enter a valid value for total price"
        case .invalidDeal: "Please leave the deal empty or enter a valid value"
        case .invalidDiners: "Please enter a valid number of diners"
        case .emptyReview: "Please enter some reviews about the meal"
        case .mapKeyError: "Map has an issue"
        case .databaseError: "Database failure, please try again"
        }
    }
}

class LogReviewUseCase {
    private let reviewRepository: ReviewRepository
    private let restaurantRepository: RestaurantRepository
    private let currentUserID: () -> String?
    
    init(reviewRepository: ReviewRepository = FirebaseReviewRepository(),
         restaurantRepository: RestaurantRepository = FirebaseRestaurantRepository(),
         currentUserID: @escaping () -> String? = { Auth.auth().currentUser?.uid }) {
        self.reviewRepository = reviewRepository
        self.restaurantRepository = restaurantRepository
        self.currentUserID = currentUserID
    }
    
    func execute(
        mealOccasion: MealOccasion,
        dishes: [DishEntry],
        numDiners: Int,
        totalPrice: Double,
        ratings: RatingScores,
        description: String,
        usedDeal: Deal,
        restaurantIdentifier: MapIdentifier,
        restaurantName: String,
        addedRestaurantTags: [CuisineTag],
        lat: Double,
        lng: Double
    ) async -> Result<String, LogReviewError> {
        guard let authorID = currentUserID() else { return .failure(.authenticationRequired) }
        guard mealOccasion != .none else { return .failure(.invalidMealOccasion) }
        guard numDiners > 0 else { return .failure(.invalidDiners) }
        guard !dishes.isEmpty else { return .failure(.dishesEmpty) }
        guard !dishes.contains(where: { !$0.isValid }) else { return .failure(.invalidDish) }
        guard totalPrice > 0 else { return .failure(.invalidPrice) }
        guard !description.isEmpty else { return .failure(.emptyReview) }
        guard usedDeal.isValid else { return .failure(.invalidDeal) }
        

        do {
            // find restaurant by id key, if not found would create one and geyt back to it
            var foundRestaurant = try await restaurantRepository.findOrCreateRestaurant(id: restaurantIdentifier, restaurantName: restaurantName, lat: lat, lng: lng)
            // Unique tags to ensure nothing comes in multiple times
            foundRestaurant.tags = Array(Set(foundRestaurant.tags + addedRestaurantTags))
            
            let createdReview = Review(
                authorID: authorID,
                mealOccasion: mealOccasion,
                dishes: dishes,
                numDiners: numDiners,
                totalPrice: totalPrice,
                ratings: ratings,
                description: description,
                usedDeal: usedDeal,
                restaurant: foundRestaurant
            )
            try await reviewRepository.save(createdReview, with: foundRestaurant)
            
            return .success(("Successfully logged review for \(createdReview.mealOccasion) at \(foundRestaurant.name)"))
        }
        catch {
            return .failure(.databaseError)
        }
    }
    
    func retrieveTagsForRestaurant(mapIdentifier: MapIdentifier) async -> [CuisineTag] {
        do {
            guard let restaurant = try await restaurantRepository.find(by: mapIdentifier) else { return [] }
            return restaurant.tags
        } catch { return [] }
    }
}
