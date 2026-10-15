//
//  ReviewCard.swift
//  MealScout
//
//  Created by CLChou on 2026/10/6.
//

import SwiftUI

struct ReviewCard: View {
    var review: Review
    var reviewDishNames: String { return review.dishes.map { $0.dishName }.joined(separator: ", ") }
    var reviewPrice: String { return String(format: "$%.2f", review.totalPrice / Double(review.numDiners)) }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Occasion & Date
            HStack {
                Text(review.mealOccasion.label)
                    .font(.headline)
                Spacer()
                Text(formattedDate(date: review.writtenDate))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Dishes List
            Text("Dishes: \(reviewDishNames)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
            
            // Diners & Price PP
            HStack {
                Text("Diners: \(review.numDiners)")
                    .font(.subheadline)
                Spacer()
                Text("Price PP: \(reviewPrice)")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            
            Divider()
                .padding(.vertical, 2)
            
            // Ratings Header & Score Row
            Text("Ratings:")
                .font(.caption)
                .foregroundStyle(.secondary)
                
            HStack {
                Spacer()
                VStack(spacing: 2) {
                    Text("Quality")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f★", review.ratings.quality))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                Spacer()
                VStack(spacing: 2) {
                    Text("Price")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f★", review.ratings.price))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                Spacer()
                VStack(spacing: 2) {
                    Text("Portion")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f★", review.ratings.portion))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    func formattedDate(date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if let daysAgo = calendar.dateComponents([.day], from: date, to: now).day {
            switch daysAgo {
            case 0:
                return "Today"
            case 1:
                return "Yesterday"
            case 2...30:
                return "\(daysAgo)d ago"
            default: break
            }
        }
        return date.formatted(.dateTime.day().month(.abbreviated).year())
    }
}

