//
//  SeedData.swift
//  MealScout
//
//  Created by CLChou on 2026/10/6.
//

import CoreData
import MapKit
import Foundation

struct SeedData {
    static func clearData(context: NSManagedObjectContext) {
        let reviewRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ReviewEntity")
        let deleteReviewRequest = NSBatchDeleteRequest(fetchRequest: reviewRequest)
        let restaurantRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "RestaurantEntity")
        let deleteRestaurantRequest = NSBatchDeleteRequest(fetchRequest: restaurantRequest)
        
        do {
            try context.execute(deleteReviewRequest)
            try context.execute(deleteRestaurantRequest)
            
        } catch {
            print("\(error)")
        }
        
        do {
            try context.save()
            context.reset()
            print("Shared Core Data context reset complete.")
            try print("Restaurants: \(CoreDataRestaurantRepository().fetchAll().count)")
            try print("Reviews: \(CoreDataReviewRepository().fetchAll().count)")
        } catch {
            print("Error saving after deletion: \(error)")
        }
        
        
    }
    
    static func seedData(context: NSManagedObjectContext) {
        let reviewRepository = CoreDataReviewRepository()
        let restaurantRepository = CoreDataRestaurantRepository()
        
        let fetchRequest: NSFetchRequest<RestaurantEntity> = RestaurantEntity.fetchRequest()
        guard (try? context.count(for: fetchRequest)) == 0 else { return }
        
        // 1. Raw Seed Data
        let rawRestaurants: [(id: String, name: String, tags: [CuisineTag])] = [
            ("I385AFE206B1B222B", "Bar Totti", [.drinksFocused, .country(code: "IT")]),
            ("IDD69762D766A8A07", "Mr. Wong", [.country(code: "CN")]),
            ("ID80634E46D93A9F9", "The Meat & Wine Co", [.drinksFocused, .bbq]),
            ("I857224021BBCC11B", "6HEAD Sydney", [.buffet, .seafood])
        ]
        
        // 2. Build a Lookup Dictionary [MapIdentifier: Restaurant]
        var restaurantMap: [String: Restaurant] = [:]
        
        for item in rawRestaurants {
            if let identifier = MapIdentifier(rawValue: item.id) {
                let restaurant = Restaurant(id: identifier, name: item.name, tags: item.tags)
                restaurantMap[item.id] = restaurant
                do { try restaurantRepository.save(restaurant) }
                catch { print (error) }
            }
        }
        
        
        let rawReviews = SeedData.getReviewData()
        for i in 0...3 {
            if let restaurant = restaurantMap[rawRestaurants[i].id] {
                for j in 0...2 {
                    if i * 3 + j >= rawReviews.count { break }
                    let r = rawReviews[i * 3 + j]
                    let review = Review(mealOccasion: r.mealOccasion, dishes: r.dishes, numDiners: r.numDiners, totalPrice: r.totalPrice, ratings: r.ratings, description: r.description, usedDeal: r.usedDeal, restaurant: restaurant)
                    do { try reviewRepository.save(review) }
                    catch { print(error) }
                    
                }
            }
        }
        
    }
    static func getReviewData() -> [reviewData] {
        return [
            // BAR TOTTI
            reviewData(
                mealOccasion: .lunch,
                dishes: [DishEntry(dishName: "Carbonara", price: 20.0, quantity: 1)],
                numDiners: 1,
                totalPrice: 20.5,
                ratings: RatingScores(quality: 4.5, price: 3.5, portion: 4.5),
                description: "Was a pretty authentic carbonara, unlike other chains which use bacon and heavy cream, they are using the correct ingredients. Approved.",
                usedDeal: nil
            ),
            reviewData(
                mealOccasion: .dinner,
                dishes: [
                    DishEntry(dishName: "Pappardelle Bolognese", price: 34.0, quantity: 2),
                    DishEntry(dishName: "Burrata", price: 20.0, quantity: 1),
                    DishEntry(dishName: "Tiramisu", price: 10.0, quantity: 1)
                ],
                numDiners: 2,
                totalPrice: 98.0,
                ratings: RatingScores(quality: 2.5, price: 1.5, portion: 2.0),
                description: "Extremely overrated and overpriced for what it is. Pasta was lukewarm and under-seasoned, service was rushed, and $98 for two people left us starving. You pay purely for the scene.",
                usedDeal: nil
            ),
            reviewData(
                mealOccasion: .drink,
                dishes: [
                    DishEntry(dishName: "Aperol Spritz", price: 12.0, quantity: 2),
                    DishEntry(dishName: "Prosciutto di Parma", price: 18.0, quantity: 1)
                ],
                numDiners: 2,
                totalPrice: 30.0,
                ratings: RatingScores(quality: 4.5, price: 4.8, portion: 4.2),
                description: "Caught the weekday Aperitivo hour. Half-price spritzes made the price tag far more reasonable for George St. Great outdoor courtyards vibe.",
                usedDeal: Deal(redeemSource: "Store", percentOff: 50, dollarsOff: 0, notes: "Happy hour in store, 15:00-17:00 50% off drinks")
            ),
            // Mr Wong
            reviewData(
                mealOccasion: .dinner,
                dishes: [
                    DishEntry(dishName: "Special Fried Rice", price: 16.0, quantity: 1),
                    DishEntry(dishName: "Spring Rolls", price: 6.0, quantity: 1)
                ],
                numDiners: 2,
                totalPrice: 20.90,
                ratings: RatingScores(quality: 4.0, price: 4.8, portion: 4.0),
                description: "Paid cash at the register to dodge the card fee and bag a 5% cash discount. Split the fried rice between two of us. Fed two people in the CBD for $10 each.",
                usedDeal: Deal(redeemSource: "Store", percentOff: 5, dollarsOff: 0, notes: "5% off total bill when paying physical cash")
            ),
            reviewData(
                mealOccasion: .lunch,
                dishes: [
                    DishEntry(dishName: "Discount Noodles", price: 10.0, quantity: 1),
                    DishEntry(dishName: "Chili Oil Side", price: 1.5, quantity: 1)
                ],
                numDiners: 1,
                totalPrice: 14.50,
                ratings: RatingScores(quality: 1.5, price: 1.0, portion: 1.5),
                description: "Noodles did not have good texture and was little. Then saw a random $3 'holiday surcharge' auto-added to the receipt on a normal Tuesday. Absolute fraud.",
                usedDeal: nil
            ),
            reviewData(
                mealOccasion: .lunch,
                dishes: [
                    DishEntry(dishName: "Pork and chive dumpling * 10", price: 12.0, quantity: 1),
                    DishEntry(dishName: "Stir fried gai lan", price: 18, quantity: 1),
                    DishEntry(dishName: "White Rice", price: 4.5, quantity: 2),
                    DishEntry(dishName: "Roast Pork (L)", price: 25, quantity: 1)
                ],
                numDiners: 2,
                totalPrice: 57.60, // $11.50 + 3.3% card surcharge
                ratings: RatingScores(quality: 4.5, price: 3.8, portion: 3.0),
                description: "Not a lot of vegetable options so we had to go for an overpriced one. Food tasted good, but the dumplings had rather less filling.",
                usedDeal: Deal(redeemSource: "EatClub", percentOff: 10, dollarsOff: 0, notes: "Eatclub deal 12:00-13:30")
            ),
            reviewData(
                mealOccasion: .lunch,
                dishes: [
                    DishEntry(dishName: "Lunch Rump Steak Set", price: 23.0, quantity: 1),
                    DishEntry(dishName: "Chips", price: 0.0, quantity: 1),
                    DishEntry(dishName: "Coke", price: 0.0, quantity: 1)
                ],
                numDiners: 1,
                totalPrice: 21.85, // $23 - 5% cash off + 70c card fee avoided
                ratings: RatingScores(quality: 4.0, price: 4.5, portion: 3.8),
                description: "Paid cash at the counter for 5% off. Steak was surprisingly juicy, best cheap protein hit in the area.",
                usedDeal: Deal(redeemSource: "Store", percentOff: 5, dollarsOff: 0, notes: "5% off when paying cash")
            ),
            reviewData(
                mealOccasion: .lunch,
                dishes: [
                    DishEntry(dishName: "200g Sirloin Steak", price: 25.0, quantity: 1),
                ],
                numDiners: 1,
                totalPrice: 27.5,
                ratings: RatingScores(quality: 4.2, price: 4.0, portion: 3.5),
                description: "Solid protein hit for under twenty bucks. Ten percent weekend surcharge",
                usedDeal: nil
            ),
            reviewData(
                mealOccasion: .dinner,
                dishes: [
                    DishEntry(dishName: "Pork Ribs Half Rack", price: 32.0, quantity: 1),
                    DishEntry(dishName: "Loaded Chips", price: 12.0, quantity: 1)
                ],
                numDiners: 2,
                totalPrice: 35.20, // $44 subtotal - 20% EatClub
                ratings: RatingScores(quality: 3.8, price: 4.2, portion: 4.0),
                description: "Grabbed an early bird 20% EatClub voucher at 5 PM. Split the ribs and chips with a mate for $17.60 each, great feed on a budget.",
                usedDeal: Deal(redeemSource: "EatClub", percentOff: 20, dollarsOff: 0, notes: "EatClub 20% off bill between 17:00-18:00")
            ),
            reviewData(
                mealOccasion: .dinner,
                dishes: [
                    DishEntry(dishName: "Buffet for one", price: 100, quantity: 1)
                ],
                numDiners: 1,
                totalPrice: 70.7,
                ratings: RatingScores(quality: 2.0, price: 1.5, portion: 2.0),
                description: "Had a wide selection of options, but none was done well. The only good options were the desserts and the roast beef. Was still extremely overpriced after the discount.",
                usedDeal: Deal(redeemSource: "EatClub", percentOff: 30, dollarsOff: 0, notes: "30% off after 8 pm")
            )
        ]
    }
        
    struct reviewData {
        let mealOccasion: MealOccasion
        let dishes: [DishEntry]
        let numDiners: Int
        let totalPrice: Double
        let ratings: RatingScores
        let description: String
        let usedDeal: Deal?
    }
}
