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
    
    static let foodCategories: Set<MKPointOfInterestCategory> = [.restaurant, .cafe, .bakery, .brewery, .winery, .distillery, .nightlife, .foodMarket]
    
    static func transportTime(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, isWalking: Bool) async -> Int? {
        let request = MKDirections.Request()
        request.source = MKMapItem(location: CLLocation(latitude: from.latitude, longitude: from.longitude), address: nil)
        request.destination = MKMapItem(location: CLLocation(latitude: to.latitude, longitude: to.longitude), address: nil)
        request.transportType = isWalking ? .walking : .transit
        
        do {
            let eta = try await MKDirections(request: request).calculateETA()
            let mins = Int(eta.expectedTravelTime / 60)
            return mins <= 20 ? mins : nil
        } catch {
            print(error)
            return nil
        }
    }
}
