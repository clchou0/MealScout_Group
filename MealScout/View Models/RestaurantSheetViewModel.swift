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
    
    init(mapItem: MKMapItem) {
        self.mapItem = mapItem
        loadReviews()
        loadTags()
    }
    
    func loadTags() {
        if let identifier = mapItem.identifier {
            self.cuisineTags = useCase.fetchTagsFromRestaurant(mapIdentifier: identifier).sorted{ $0.labelName < $1.labelName }
        } else {
            self.cuisineTags = []
        }
    }
    
    func loadReviews() {
        guard let identifier = mapItem.identifier else {
            self.reviews = []
            return
        }
        self.reviews = useCase.fetchReviewsFromRestaurant(mapIdentifier: identifier)
    }
}
