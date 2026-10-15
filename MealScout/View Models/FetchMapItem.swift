//
//  FetchMapItem.swift
//  MealScout
//
//  Created by CLChou on 2026/10/7.
//
import MapKit
import Foundation
import SwiftUI


class FetchMapItem {
    static func getByString(from identifierString: String) async -> MKMapItem? {
        guard let identifier = MKMapItem.Identifier(rawValue: identifierString) else {
            print("Invalid identifier string format")
            return nil
        }
        
        let request = MKMapItemRequest(mapItemIdentifier: identifier)
        
        do {
            let mapItem = try await request.mapItem
            return mapItem
        } catch {
            print("Failed to resolve MKMapItem: \(error)")
            return nil
        }
    }
    
    static func getByFeature(for feature: MapFeature) async -> MKMapItem? {
        let request = MKMapItemRequest(feature: feature)
        do {
            return try await request.mapItem
        } catch {
            print("Failed to get map item: \(error.localizedDescription)")
            return nil
        }
    }
    
    static let foodCategories: Set<MKPointOfInterestCategory> = [.restaurant, .cafe, .bakery, .brewery, .winery, .distillery, .nightlife, .foodMarket, .store]
}
