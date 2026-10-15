//
//  LogReviewViewModel.swift
//  MealScout
//
//  Created by CLChou on 2026/9/23.
//

import Foundation

@Observable
class LogReviewViewModel {
    let restaurantIdentifier: MapIdentifier
    let restaurantName: String
    
    var mealOccasion: MealOccasion = .none
    var dishes: [DishEntry] = []
    var numDiners: Int = 1
    
    var ratings: RatingScores = RatingScores()
    var description: String = ""
    
    var usedDeal: Deal = Deal()
    var totalPrice: Double = 0
    
    var newRestaurantTags: [CuisineTag] = []
    var originalTags: [CuisineTag]
    
    var newSelection: CuisineTag? = nil
    
    var displayedTotalPrice: Double {
        // Note: We asked for the original prices, and the user might have paid different from the aggregate of the items.
        return totalPrice != 0 ? totalPrice : dishes.reduce(0) { $0 + $1.price }
    }
    
    var alertItem: AlertItem? = nil
    let useCase: LogReviewUseCase = LogReviewUseCase()
    
    init(restaurantIdentifier: MapIdentifier, restaurantName: String) {
        self.restaurantIdentifier = restaurantIdentifier
        self.restaurantName = restaurantName
        
        self.originalTags = useCase.retrieveTagsForRestaurant(mapIdentifier: restaurantIdentifier)
    }
    
    func submitReview(dismiss: @escaping () -> Void) {
        let result = useCase.execute(
            mealOccasion: mealOccasion,
            dishes: dishes, numDiners: numDiners,
            totalPrice: displayedTotalPrice,
            ratings: ratings,
            description: description,
            usedDeal: usedDeal,
            restaurantIdentifier: restaurantIdentifier,
            restaurantName: restaurantName,
            addedRestaurantTags: newRestaurantTags
        )
        
        switch (result) {
        case .failure(let error):
            alertItem = AlertItem(title: "Error", message: error.errorDescription ?? "Unknown...")
        case .success(let message):
            alertItem = AlertItem(title: "Success", message: message, delegate: { dismiss() })
        }
    }
    
    func handleLeaveScreen(dismiss: @escaping () -> Void) {
        alertItem = AlertItem(
            title: "Exit",
            message: "Your changes will not be saved...",
            delegate: { dismiss() },
            cancelDelegate: {}
        )
    }
}
