//
//  MapViewModel.swift
//  MealScout
//
//  Created by CLChou on 2026/9/28.
//

import Foundation
import MapKit
import SwiftUI

@Observable
class MapViewModel {
    var position: MapCameraPosition = MapCameraPosition.region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    ))
    
    var selectedFeature: MapFeature? = nil
    var presentRestaurantSheet: Bool = false
    var presentFilterSheet: Bool = false
    var presentResultsSheet: Bool = false
    
    var mapItem: MKMapItem? = nil
    var filter = FilterObject()
    let useCase = FilterReviewsUseCase()
    var filteredRestaurants: [Restaurant] = []
    var allReviews: [Review] = []
    var alertItem: AlertItem? = nil
    
    init() {
        
    }
    
    func handleChangeFeature(feature: MapFeature) {
        print("Tapped: \(feature.title ?? "unknown")")
        Task {
            guard let mapItem = await FetchMapItem.getByFeature(for: feature) else {
                presentRestaurantSheet = false
                return
            }
            self.mapItem = mapItem
        }
    }
    
    func handleChangeMapItem(mapItem: MKMapItem) {
        print("\(mapItem.name ?? "unknown"): \(mapItem.identifier?.rawValue ?? "unknown")")
        presentRestaurantSheet = true
    }
    
    func reloadAllReviews() {
        do {
            try allReviews = useCase.fetchAllReviews()
        } catch {
            print(error)
        }
    }
    
    func reloadFilteredRestaurants() {
        let result = useCase.execute(allReviews: allReviews, filter: filter)
        switch result {
            case .success(let restaurants): filteredRestaurants = restaurants
            case .failure(let error): print(error)
        }
    }
    
    func goToRestaurant(id: MapIdentifier) {
        Task {
            if let restaurantItem = await FetchMapItem.getByString(from: id.rawValue) {
                mapItem = restaurantItem
                presentResultsSheet = false
            }
        }
    }
    
    func checkForSharedPlace() async {
        print("CHECKING")
        guard let id = UserDefaults(suiteName: "group.MealScout")?.string(forKey: "shared_place_id") else {
            print("not found")
            return
        }
        UserDefaults(suiteName: "group.MealScout")?.removeObject(forKey: "shared_place_id")
        print("APP GOT: \(id)" )
        
        Task {
            if let item = await FetchMapItem.getByString(from: id) {
                print("GOT ITEM!!: \(item.name ?? "Unknown")")
                guard let category = item.pointOfInterestCategory else {
                    print("NO CATEGORY!!")
                    alertItem = AlertItem(
                        title: "Category invalid",
                        message: "\(item.name ?? "Unknown place") does not have a valid category"
                    )
                    return
                }
                guard FetchMapItem.foodCategories.contains(category) else {
                    print("WOORNG CATEGORY!")
                    alertItem = AlertItem(
                        title: "Category invalid",
                        message: "\(item.name ?? "Unknown place") is not a restaurant"
                    )
                    return
                }
                self.mapItem = item
            }
        }
        
    }
}
