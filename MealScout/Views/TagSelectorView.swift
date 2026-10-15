//
//  TagSelectorView.swift
//  MealScout
//
//  Created by CLChou on 2026/9/30.
//

import SwiftUI

/// Modes:
///  1. Review: would stack up the options on top of the previous ones:
///  2. Filter: Would be built from ground up


struct TagSelectorView: View {
    let originalSelectedTags: [CuisineTag]
    @Binding var newSelectedTags: [CuisineTag]
    @State var newSelection: CuisineTag?
    @State var currentSelection: CuisineTag? = nil
    
    @State var filter: String = ""
    
    private var filteredTags: [CuisineTag] {
        CuisineTag.allCases.filter { tag in
            let wasNotSelected = !originalSelectedTags.contains(tag)
            let isNotSelected = !newSelectedTags.contains(tag)
            let matchesSearch = filter.isEmpty || tag.labelName.localizedCaseInsensitiveContains(filter)
            
            return isNotSelected && matchesSearch && wasNotSelected
        }
    }
    
    var body: some View {
        VStack {
            TextField("", text: $filter).textFieldStyle(.roundedBorder)
            
            HStack {
                Picker("", selection: $currentSelection) {
                    Text("Select a tag...").dimText().font(.system(size: 20))
                        .tag(CuisineTag?.none)
                    
                    ForEach(filteredTags, id: \.self) { tag in
                        Text("\(tag.displayIcon) \(tag.labelName)")
                            .font(.system(size: 20))
                            .tag(tag)
                    }
                }
                .frame(height: 100)
                .pickerStyle(.wheel)
                
                Button {
                    newSelection = currentSelection
                    currentSelection = nil
                    filter = ""
                } label: {
                    HStack {
                        Image(systemName: "plus.square.fill")
                        Text("Add")
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
                .disabled(currentSelection == nil)
            }
            ScrollView (.horizontal) {
                HStack (spacing: 5) {
                    ForEach(newSelectedTags, id: \.self) { tag in
                        CuisineTagCard(
                            tag: tag,
                            delegate: {
                                newSelectedTags.removeAll(where: { $0 == tag })
                            }
                        )
                    }
                }
            }
            .defaultScrollAnchor(.trailing)
        }
        .onChange(of: newSelection) {
            // Add the respective value and clear out selection
            if let selection = newSelection {
                print("\(selection.labelName) added")
                newSelectedTags.append(selection)
                newSelection = nil
            }
        }
    }
    
    private struct CuisineTagCard: View {
        var tag: CuisineTag
        var delegate: () -> Void
        var body: some View {
            HStack(spacing: 8) {
                // Tag Text
                Text("\(tag.displayIcon) \(tag.labelName)")
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
}

#Preview {
    @Previewable @State var sampleTags: [CuisineTag] = []
    TagSelectorView(originalSelectedTags: sampleTags, newSelectedTags: $sampleTags)
}
