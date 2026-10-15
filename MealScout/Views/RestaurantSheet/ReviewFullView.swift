//
//  ReviewSheet.swift
//  MealScout
//
//  Created by CLChou on 2026/10/6.
//

import SwiftUI

struct ReviewFullView: View {
    let review: Review
    var discountStr: String {
        guard let deal = review.usedDeal, !deal.isEmpty else { return "" }
        
        var parts: [String] = []
        
        if deal.percentOff > 0 {
            parts.append("\(deal.percentOff)% off")
        }
        if deal.dollarsOff > 0 {
            parts.append(String(format: "$%.2f off", deal.dollarsOff))
        }
        
        return parts.joined(separator: ", ")
    }

    var body: some View {
        VStack {
            HStack {
                Text("Review for ")
                Text(review.restaurant.name).fontWeight(.bold)
            }
            .font(.title3)
            .padding(.top)

            List {
                // Section 1: Meal Info
                Section {
                    LabeledContent("Meal Time", value: review.mealOccasion.label)
                    LabeledContent("Date", value: review.writtenDate.formatted(date: .abbreviated, time: .omitted))
                    LabeledContent("Number of Diners", value: "\(review.numDiners)")
                } header: {
                    Text("Meal Overview")
                        .font(serifFont)
                        .foregroundStyle(.gray)
                }

                Section {
                    if let deal = review.usedDeal {
                        LabeledContent("Source", value: deal.redeemSource)
                    } else {
                        Text("N/A")
                    }
                } header: {
                    Text("Deal Applied")
                        .font(serifFont)
                        .foregroundStyle(.gray)
                }
                // Section 2: Deal Information (Conditional)
                if let deal = review.usedDeal, !deal.isEmpty {
                    Section {
                        LabeledContent("Source", value: deal.redeemSource)
                        
                        LabeledContent("Discount", value: discountStr)

                        if !deal.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Notes")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(deal.notes)
                                    .font(.subheadline)
                            }
                        }
                    } header: {
                        
                    }
                } else {
                    
                }

                // Section 3: Dishes
                Section {
                    ForEach(review.dishes) { dish in
                        HStack {
                            
                            Text(dish.dishName)
                                .font(.body)
                            if dish.quantity > 1 {
                                Text("✕ \(dish.quantity)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(String(format: "$%.2f", dish.price))
                                .font(.subheadline)
                        }
                    }
                } header: {
                    Text("Dishes")
                        .font(serifFont)
                        .foregroundStyle(.gray)
                }

                // Section 4: Total Price & Per-Person Cost
                Section {
                    LabeledContent("Total Paid", value: String(format: "$%.2f", review.totalPrice))
                        .fontWeight(.semibold)
                    
                    if review.numDiners > 0 {
                        LabeledContent("Cost Per Person", value: String(format: "$%.2f", review.totalPrice / Double(review.numDiners)))
                            .foregroundStyle(.green)
                            .fontWeight(.bold)
                    }
                } header: {
                    Text("Price Summary")
                        .font(serifFont)
                        .foregroundStyle(.gray)
                }

                if !review.description.isEmpty {
                    Section {
                        Text(review.description)
                            .font(.body)
                    } header: {
                        Text("Review & Comments")
                            .font(serifFont)
                            .foregroundStyle(.gray)
                    }
                }

                // Section 6: Ratings Breakdown
                Section {
                    RatingDisplayRow(title: "Quality", score: review.ratings.quality)
                    RatingDisplayRow(title: "Portion", score: review.ratings.portion)
                    RatingDisplayRow(title: "Price / Value", score: review.ratings.price)
                } header: {
                    Text("Ratings")
                        .font(serifFont)
                        .foregroundStyle(.gray)
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

struct RatingDisplayRow: View {
    let title: String
    let score: Double // e.g. 4.2
    
    var body: some View {
        HStack {
            // Category Title
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            // Fractional Stars (Baseline of 5)
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { index in
                    fractionalStar(for: index)
                }
            }
            
            // Score Value
            Text(String(format: "%.1f", score))
                .font(.subheadline)
                .fontWeight(.bold)
                .monospacedDigit()
                .frame(width: 32, alignment: .trailing)
        }
    }
    
    private func fractionalStar(for index: Int) -> some View {
        let fillAmount = max(0.0, min(1.0, score - Double(index)))
        
        return ZStack {
            Image(systemName: "star")
                .foregroundStyle(.gray.opacity(0.3))
            
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
                .mask(
                    GeometryReader { geo in
                        Rectangle()
                            .frame(width: geo.size.width * fillAmount, height: geo.size.height)
                    }
                )
        }
    }
}


