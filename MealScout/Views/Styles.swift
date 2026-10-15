//
//  Styles.swift
//  MealScout
//
//  Created by CLChou on 2026/9/25.
//

import SwiftUI

let serifFont: Font =
    .system(size: 20, weight: .bold, design: .serif)

extension Text {
    func dimText() -> some View {
        self
            .foregroundStyle(Color.gray)
            .opacity(0.7)
    }
}

