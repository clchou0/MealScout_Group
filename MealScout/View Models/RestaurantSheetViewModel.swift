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
        Task {
            await loadReviews()
            await loadTags()
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
