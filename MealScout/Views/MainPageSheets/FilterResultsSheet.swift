//
//  FilterResultsSheet.swift
//  MealScout
//
//  Created by CLChou on 2026/10/6.
//

import SwiftUI

struct FilterResultsSheet: View {
    var delegate: (_ selectedId: MapIdentifier) -> Void
    var filteredRestaurants: [Restaurant]
    var body: some View {
        Group {
            if filteredRestaurants.isEmpty {
                ContentUnavailableView {
                    Label("No Matching Restaurants", systemImage: "fork.knife")
                } description: {
                    Text("No restaurant reviews match your selected filters yet. Try another tag or adjust your filters.")
                }
            } else {
                Form {
                    Section {
                        ForEach(filteredRestaurants) { restaurant in
                            RestaurantCard( restaurant: restaurant, delegate: delegate )
                        }
                    }
                }
            }
        }
    }
}

struct RestaurantCard: View {
    let restaurant: Restaurant
    let delegate: (_ selectedId: MapIdentifier) -> Void
    var body: some View {
        HStack {
            Text(restaurant.name).font(.caption2)
            Spacer()
            Button {
                delegate(restaurant.id)
            } label: {
                Image(systemName: "chevron.right")
            }
        }
    }
}
