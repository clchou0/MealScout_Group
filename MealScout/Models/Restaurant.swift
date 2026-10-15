//
//  Restaurant.swift
//  MealScout
//
//  Created by CLChou on 2026/9/23.
//

import Foundation
import MapKit

typealias MapIdentifier = MKMapItem.Identifier

/// An object that represents a restaurant, which links to a placemark

struct Restaurant: Identifiable, Codable, Equatable {
    let id: MapIdentifier
    var name: String
    var tags: [CuisineTag]
    
//    init(id: MapIdentifier, name: String, tag: [CuisineTag]) {
//        self.id = id
//        self.name = name
//        self.tag = tag
//    }
}
