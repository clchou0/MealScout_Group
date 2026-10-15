//
//  RatingSlider.swift
//  MealScout
//
//  Created by CLChou on 2026/9/26.
//

import SwiftUI

struct RatingSlider: View {
    let name: String
    let description: String
    @Binding var rating: Double
    
    var body: some View {
        HStack {
            Text("\(Text("\(name):").fontWeight(.bold))")
            Spacer()
            Text("\(description)?")
                .dimText()
        }
        HStack {
            Text("\(rating, specifier: "%.1f")")
            Slider(
                value: $rating,
                in: 1...5,
                step: 0.1
            ) {}
        }
    }
}

#Preview {
    @Previewable @State var rating = 3.0
    RatingSlider(name: "Price", description: "How was the value for the price given?", rating: $rating)
}
