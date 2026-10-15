//
//  AlertItem.swift
//  MealScout
//
//  Created by CLChou on 2026/9/24.
//

import Foundation
import SwiftUI

struct AlertItem: Identifiable {
    let id: UUID = UUID()
    let title: String
    let message: String
    var delegate: () -> Void = { return }
    var cancelDelegate: (() -> Void)? = nil
}

///
/// Customized alert item where an object supplies its fields
/// 1. Title
/// 2. Message
/// 3. OK button led to function
/// 4. Cancel button led to function
/// ** As ok and cancel buttons are pressed, unloads them from dock
///
struct AlertItemModifier: ViewModifier {
    @Binding var alertItem: AlertItem?
    
    func body(content: Content) -> some View {
        content.alert(
            alertItem?.title ?? "",
            isPresented: Binding(
                get: { alertItem != nil },
                set: { _ in }
            ),
            presenting: alertItem
        ) { item in
            HStack {
                Button("OK") {
                    item.delegate()
                    alertItem = nil
                }
                
                if (item.cancelDelegate != nil) {
                    Button("Cancel") {
                        item.cancelDelegate!()
                        alertItem = nil
                    }
                }
            }
        } message: { item in
            Text(item.message)
        }
    }
}

extension View {
    func resultAlert(alertItem: Binding<AlertItem?>) -> some View {
        modifier(AlertItemModifier(alertItem: alertItem))
    }
}
