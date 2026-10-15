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
        Form {
            Section {
                ForEach(filteredRestaurants) { restaurant in
                    RestaurantCard(restaurant: restaurant, delegate: delegate)
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
