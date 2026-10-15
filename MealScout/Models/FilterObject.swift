//
//  FilterObject.swift
//  MealScout
//
//  Created by CLChou on 2026/10/6.
//

/// An object that stores what is necessary for a filter, can check against reviews to see if they match

import Foundation
struct FilterObject: Equatable {
    var restaurantName: String = ""
    var dishName: String = ""
    
    var oneDinerRestrict: Bool = false
    var desiredPricePP: Double = .infinity
    var selectedMealTypes: [MealOccasion] = []
    
    var selectedCuisineTags: [CuisineTag] = []
    var newSelectedTag: CuisineTag? = nil
    
    var desiredRating: RatingScores = RatingScores(quality: 1.0, price: 1.0, portion: 1.0)
    
    
    func evaluate (review: Review) -> Bool {
        guard restaurantName.isEmpty || review.restaurant.name.localizedCaseInsensitiveContains(restaurantName) else { return false }
        
        guard dishName.isEmpty || review.dishes.contains(where: { $0.dishName.localizedCaseInsensitiveContains(dishName)
        }) else { return false }
        
        guard selectedMealTypes.isEmpty || selectedMealTypes.contains(review.mealOccasion) else { return false }
        
        if oneDinerRestrict {
            guard review.numDiners == 1 else { return false }
        }
        
        guard desiredPricePP >= (review.totalPrice / Double(review.numDiners)) else { return false }
        
        guard selectedCuisineTags.isEmpty ||
                review.restaurant.tags.contains(where: { selectedCuisineTags.contains($0) })
            else { return false }
        
        let rate = review.ratings
        guard rate.quality >= desiredRating.quality
                && rate.portion >= desiredRating.portion
                && rate.price >= desiredRating.price else { return false }
        
        return true
    }
    
    var isDefault: Bool { self == FilterObject() }
}
