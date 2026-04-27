//
//  View+Glass.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 20/04/2026.
//

import SwiftUI

extension View {

    /// Applies the given transform only when `condition` is `true`.
    ///
    /// Use this to conditionally attach modifiers without breaking the modifier chain:
    /// ```swift
    /// view.if(showMenu) { $0.contextMenu { ... } }
    /// ```
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool,
                               transform: (Self) -> Transform) -> some View {
        if condition { transform(self) } else { self }
    }

    /// Clips the view to a circle and applies an iOS 26 glass effect.
    /// Falls back to `ultraThinMaterial` on iOS 15–25.
    @ViewBuilder
    func glassCircle() -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(in: Circle())
        } else {
            self
                .background(Circle().fill(.regularMaterial))
                .overlay(Circle().stroke(Color(.separator), lineWidth: 0.5))
        }
    }

    /// Clips the view to a rounded rectangle and applies an iOS 26 glass effect.
    /// Falls back to `regularMaterial` on iOS 15–25.
    @ViewBuilder
    func glassRoundedRect(cornerRadius: CGFloat = 20) -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
        } else {
            self
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.regularMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
        }
    }
}
