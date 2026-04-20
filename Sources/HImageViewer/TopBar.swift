//
//  TopBar.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 09/07/2025.
//

import SwiftUI

struct TopBar: View {
    let config: TopBarConfig

    var body: some View {
        ZStack {
            // Centered page counter — sits independently of leading/trailing buttons
            if let counter = config.pageCounterText {
                Text(counter)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: counter)
            }

            // Leading / trailing buttons
            HStack {
                if config.selectionMode {
                    Button("Cancel", action: config.onCancelSelection)
                        .foregroundStyle(.primary)
                        .padding(.leading, 4)
                } else {
                    CircleButton(systemName: "xmark", action: config.onDismiss)
                }
                Spacer()
                if !config.selectionMode {
                    HStack(spacing: 12) {
                        if config.showEditButton {
                            CircleButton(systemName: "pencil", action: config.onEdit)
                        }
                        if config.showSelectButton {
                            CircleButton(systemName: "checkmark.circle", action: config.onSelectToggle)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }
}

// MARK: - Supporting types

struct TopBarConfig {
    var showEditButton: Bool
    var showSelectButton: Bool
    var selectionMode: Bool
    /// Counter text shown centered in the bar, e.g. `"2 / 5"`. `nil` hides the label.
    var pageCounterText: String?
    var onDismiss: () -> Void
    var onCancelSelection: () -> Void
    var onSelectToggle: () -> Void
    var onEdit: () -> Void
}

struct CircleButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.headline)
                .foregroundStyle(.gray)
                .padding(8)
        }
        .background(
            Circle()
                .stroke(Color.gray, lineWidth: 1)
        )

    }
}
