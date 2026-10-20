//
//  RestaurantSheetViewModel.swift
//  MealScout
//
//  Created by CLChou on 2026/9/28.
//

import Foundation
import MapKit
import SwiftUI

@Observable
class RestaurantSheetViewModel {
    var mapItem: MKMapItem
    let useCase = FetchRestaurantDetailsUseCase()
    var reviews: [Review] = []
    var cuisineTags: [CuisineTag] = []
    
    var walkMins: Int?
    var transportMins: Int?
    
    init(mapItem: MKMapItem, targetLocation: CLLocationCoordinate2D) {
        self.mapItem = mapItem
        let dest = mapItem.location.coordinate
        Task {
            async let reviewLoad: () = loadReviews()
            async let tagLoad: () = loadTags()
            
            _ = await(reviewLoad, tagLoad)
            
            async let reviews: () = loadReviews()
            async let tags: () = loadTags()
            async let walk = FetchMapItem.transportTime(from: targetLocation, to: dest, isWalking: true)
            async let drive = FetchMapItem.transportTime(from: targetLocation, to: dest, isWalking: false)

            let (_, _, w, d) = await (reviews, tags, walk, drive)
            walkMins = w
            transportMins = d
        }
    }
    
    func loadTags() async {
        if let identifier = mapItem.identifier {
            self.cuisineTags = await useCase.fetchTagsFromRestaurant(mapIdentifier: identifier).sorted{ $0.labelName < $1.labelName }
        } else {
            self.cuisineTags = []
        }
    }
    
    func loadReviews() async {
        guard let identifier = mapItem.identifier else {
            self.reviews = []
            return
        }
        self.reviews = await useCase.fetchReviewsFromRestaurant(mapIdentifier: identifier)
    }
}
