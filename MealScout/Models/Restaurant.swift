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
    
    var latitude: Double
    var longitude: Double
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    enum CodingKeys: String, CodingKey {case id, name, tags, latitude, longitude}
    init(
        id: MapIdentifier,
        name: String,
        tags: [CuisineTag],
        latitude: Double,
        longitude: Double
    ) {
        self.id = id
        self.name = name
        self.tags = tags
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let rawID = try values.decode(String.self, forKey: .id)
        
        guard let identifier = MapIdentifier(rawValue: rawID) else {
            throw DecodingError.dataCorruptedError(
                forKey: .id,
                in: values,
                debugDescription: "Invalid restaurant identifier"
            )
        }
        
        id = identifier
        name = try values.decode(String.self, forKey: .name)
        tags = try values.decode([CuisineTag].self, forKey: .tags)
        latitude = try values.decode(Double.self, forKey: .latitude)
        longitude = try values.decode(Double.self, forKey: .longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        
        try values.encode(id.rawValue, forKey: .id)
        try values.encode(name, forKey: .name)
        try values.encode(tags, forKey: .tags)
        try values.encode(latitude, forKey: .latitude)
        try values.encode(longitude, forKey: .longitude)
    }
}

