//
//  PageDotsView.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 20/04/2026.
//

import SwiftUI

/// A horizontal dot strip indicating the current page within a paged view.
///
/// Dots are only rendered when `count` is between 2 and `maxDots` (inclusive).
/// Above `maxDots` the counter label in `TopBar` is sufficient.
struct PageDotsView: View {

    let currentIndex: Int
    let count: Int

    /// Maximum number of assets before dots are hidden in favour of the counter alone.
    static let maxDots = 8

    var body: some View {
        if shouldShow {
            HStack(spacing: 6) {
                ForEach(0..<count, id: \.self) { index in
                    let isActive = index == currentIndex
                    Circle()
                        .fill(isActive ? Color.white : Color.white.opacity(0.35))
                        .frame(
                            width: isActive ? 8 : 6,
                            height: isActive ? 8 : 6
                        )
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: currentIndex)
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Helpers

    var shouldShow: Bool {
        count >= 2 && count <= Self.maxDots
    }
}
