//
//  FilterResultsSheet.swift
//  MealScout
//
//  Created by CLChou on 2026/10/2.
//

import SwiftUI

struct FiltersSheet: View {
    @Binding var filter: FilterObject
    @State var newMealType: MealOccasion = .none
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Restaurant Name: ")
                    TextField("Leave empty if you don't want to filter...", text: $filter.restaurantName)
                }
                
                HStack {
                    Text("Target dishes: ")
                    TextField("Leave empty if you don't want to filter...", text: $filter.dishName)
                }
                
                HStack {
                    Text("Only display results of dining alone")
                    Spacer()
                    Toggle("", isOn: $filter.oneDinerRestrict)
                        .labelsHidden()
                }
                
                HStack {
                    Text("Target max price per person: ")
                    Spacer()
                    Text("$")
                    TextField("", value: Binding<Double?>(
                        get: { filter.desiredPricePP.isFinite ? filter.desiredPricePP : nil },
                        set: {
                            if let v = $0, v > 0 {
                                filter.desiredPricePP = (v * 100).rounded() / 100
                            } else {
                                filter.desiredPricePP = .infinity
                            }
                        }
                    ), format: .number)
                    .frame(maxWidth: 100)
                    .textFieldStyle(.roundedBorder)
                }
            }
            
            Section {
                TagSelectorView(
                    originalSelectedTags: [],
                    newSelectedTags: $filter.selectedCuisineTags
                )
            } header: {
                Text("Tags: ").font(serifFont)
            }
            
            
            Section {
                Picker("", selection: $newMealType) {
                    Text("Select a tag...").dimText().font(.system(size: 20))
                        .tag(MealOccasion.none)
                             
                    ForEach(MealOccasion.allCases, id: \.self) { occasion in
                        if (occasion != .none && !filter.selectedMealTypes.contains(occasion)) {
                            Text(occasion.label).tag(occasion)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .pickerStyle(.menu)
                
                if (filter.selectedMealTypes.isEmpty) { Text("Any").dimText() }
                
                else {
                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach (filter.selectedMealTypes, id: \.self) { meal in
                                MealOccasionCard(
                                    mealOccasion: meal,
                                    delegate: { filter.selectedMealTypes.removeAll(where: { $0 == meal }) }
                                )
                            }
                        }
                    }
                    .defaultScrollAnchor(.trailing)
                }
            } header: {
                Text("Target Meals: ").font(serifFont)
            }
            
            Section {
                starRatingPicker(title: "Portion:", rating: $filter.desiredRating.portion)
                starRatingPicker(title: "Price", rating: $filter.desiredRating.price)
                starRatingPicker(title: "Quality", rating: $filter.desiredRating.quality)
            } header: {
                Text("Minimum Rating: ").font(serifFont)
            }
            
        }.padding()
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onChange(of: newMealType) { _, newValue in
            if newValue != .none {
                filter.selectedMealTypes.append(newValue)
                newMealType = .none
            }
        }
    }
}

struct starRatingPicker: View {
    let title: String
    @Binding var rating: Double
    
    var body: some View {
        HStack {
            Text("\(title): ").frame(maxWidth: 200)
            ForEach (1...5, id: \.self) { star in
                Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                    .contentShape(Rectangle())
                    .foregroundStyle(star <= Int(rating) ? .orange : .gray)
                    .onTapGesture {
                        rating = Double(star)
                    }
            }
        }
    }
}

struct MealOccasionCard: View {
    var mealOccasion: MealOccasion
    var delegate: () -> Void
    var body: some View {
        HStack(spacing: 8) {
            // Tag Text
            Text("\(mealOccasion.label)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)

            // X Button
            Button {
                delegate()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)
                    .padding(4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemFill))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    @Previewable @State var filter = FilterObject()
    FiltersSheet(filter: $filter)
}
