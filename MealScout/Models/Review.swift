//
//  Review.swift
//  MealScout
//
//  Created by CLChou on 2026/9/23.
//

import Foundation
import MapKit

/// A review object that has all details related to a meal

enum MealOccasion: String, Hashable, Codable, CaseIterable {
    case breakfast, lunch, dinner, brunch, afternoonTea, snack, supper, dessert, beverage, drink, none
    // I would define supper as late night meal
    var label: String {
        switch self {
        case .breakfast: "Breakfast"
        case .brunch: "Brunch"
        case .lunch: "Lunch"
        case .afternoonTea: "Afternoon Tea"
        case .dinner: "Dinner"
        case .supper: "Supper (Late Night)"
        case .snack: "Snack"
        case .dessert: "Dessert"
        case .beverage: "Beverage"
        case .drink: "Drink"
        case .none: ""
        }
    }
}

struct RatingScores: Codable, Equatable {
    var quality: Double = 5.0
    var price: Double = 5.0
    var portion: Double = 5.0
}

struct Deal: Codable {
    var redeemSource: String = ""
    var percentOff: Int = 0
    var dollarsOff: Double = 0.0
    var notes: String = ""
    
    var isEmpty: Bool {
        return redeemSource.isEmpty && percentOff == 0 && dollarsOff == 0
    }
    
    var isValid: Bool {
        if (isEmpty) { return isEmpty }
        return !redeemSource.isEmpty && (percentOff >= 0 || dollarsOff >= 0.0)    // Fill both discount and source
    }
}

struct DishEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var dishName: String = ""
    var price: Double = 0
    var quantity: Int = 1
    
    var isValid: Bool {
        return !dishName.isEmpty && price >= 0.0 && quantity > 0
    }
}

struct Review: Identifiable, Codable {
    let id: UUID
    var authorID: String
    let restaurantID: String
    var isSample: Bool
    
    var mealOccasion: MealOccasion
    var writtenDate: Date
    
    // Prices of all consumed dishes
    var dishes: [DishEntry]
    var numDiners: Int
    var totalPrice: Double
    
    var ratings: RatingScores
    var description: String
    
    var usedDeal: Deal? = nil
    
    let restaurant: Restaurant
    
    init(id: UUID = UUID(), authorID: String = "", isSample: Bool = false, mealOccasion: MealOccasion, dishes: [DishEntry], numDiners: Int, totalPrice: Double, ratings: RatingScores, description: String, usedDeal: Deal? = nil, restaurant: Restaurant) {
        self.id = id
        self.authorID = authorID
        self.restaurantID = restaurant.id.rawValue
        self.isSample = isSample
        self.mealOccasion = mealOccasion
        self.writtenDate = .now
        self.dishes = dishes
        self.numDiners = numDiners
        self.totalPrice = totalPrice
        self.ratings = ratings
        self.description = description
        self.usedDeal = usedDeal
        self.restaurant = restaurant
    }
}
