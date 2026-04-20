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
            // Centered page counter
            if let counter = config.pageCounterText {
                Text(counter)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(config.isGlassMode ? .white : .primary)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: counter)
                    .accessibilityLabel(config.accessibilityPageLabel ?? counter)
            }

            // Leading / trailing controls
            HStack {
                if config.selectionMode {
                    Button("Cancel", action: config.onCancelSelection)
                        .font(.body.weight(.medium))
                        .foregroundStyle(config.isGlassMode ? .white : config.tintColor)
                        .padding(.leading, 4)
                        .accessibilityHint("Exits selection mode")
                } else {
                    CircleButton(
                        systemName: "xmark",
                        accessibilityLabel: "Close",
                        accessibilityHint: "Dismisses the viewer",
                        tintColor: config.tintColor,
                        isGlassMode: config.isGlassMode,
                        action: config.onDismiss
                    )
                }

                Spacer()

                if !config.selectionMode {
                    HStack(spacing: 10) {
                        if config.showEditButton {
                            CircleButton(
                                systemName: "pencil",
                                accessibilityLabel: "Edit",
                                accessibilityHint: "Opens the photo editor",
                                tintColor: config.tintColor,
                                isGlassMode: config.isGlassMode,
                                action: config.onEdit
                            )
                        }
                        if config.showSelectButton {
                            CircleButton(
                                systemName: "checkmark.circle",
                                accessibilityLabel: "Select",
                                accessibilityHint: "Enters selection mode",
                                tintColor: config.tintColor,
                                isGlassMode: config.isGlassMode,
                                action: config.onSelectToggle
                            )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

// MARK: - Supporting types

struct TopBarConfig {
    var showEditButton: Bool
    var showSelectButton: Bool
    var selectionMode: Bool
    /// Counter text shown centered in the bar, e.g. `"2 / 5"`. `nil` hides the label.
    var pageCounterText: String?
    /// VoiceOver label for the page counter, e.g. `"Page 2 of 5"`. Falls back to `pageCounterText` when `nil`.
    var accessibilityPageLabel: String? = nil
    /// Accent color for buttons. Used in classic (non-glass) mode.
    var tintColor: Color = .blue
    /// `true` = iOS 26 Liquid Glass style; `false` = classic bordered style.
    var isGlassMode: Bool = true
    var onDismiss: () -> Void
    var onCancelSelection: () -> Void
    var onSelectToggle: () -> Void
    var onEdit: () -> Void
}

// MARK: - CircleButton

struct CircleButton: View {
    let systemName: String
    var accessibilityLabel: String = ""
    var accessibilityHint: String? = nil
    var tintColor: Color = .blue
    var isGlassMode: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isGlassMode ? .white : tintColor)
                .frame(width: 36, height: 36)
        }
        .modifier(CircleButtonBackground(tintColor: tintColor, isGlassMode: isGlassMode))
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint ?? "")
    }
}

/// Applies either the iOS 26 glass circle or the classic gray-border circle.
private struct CircleButtonBackground: ViewModifier {
    let tintColor: Color
    let isGlassMode: Bool

    func body(content: Content) -> some View {
        if isGlassMode {
            content.glassCircle()
        } else {
            content
                .background(
                    Circle()
                        .stroke(Color.gray, lineWidth: 1)
                )
        }
    }
}
