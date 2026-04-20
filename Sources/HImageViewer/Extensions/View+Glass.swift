//
//  View+Glass.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 20/04/2026.
//

import SwiftUI

extension View {

    /// Clips the view to a circle and applies an iOS 26 glass effect.
    /// Falls back to `ultraThinMaterial` on iOS 15–25.
    @ViewBuilder
    func glassCircle() -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(in: Circle())
        } else {
            self
                .background(Circle().fill(.ultraThinMaterial))
                .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 0.5))
        }
    }

    /// Clips the view to a rounded rectangle and applies an iOS 26 glass effect.
    /// Falls back to `ultraThinMaterial` on iOS 15–25.
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
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
                )
        }
    }
}
