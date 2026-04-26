//
//  TopBar.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 09/07/2025.
//

import SwiftUI

struct TopBar: View {
    let config: TopBarConfig
    /// `true` in landscape — reduces vertical padding so more image is visible.
    var compact: Bool = false

    var body: some View {
        ZStack {
            // Centered page counter
            if let counter = config.pageCounterText {
                Text(counter)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: counter)
                    .accessibilityLabel(config.accessibilityPageLabel ?? counter)
            }

            // Leading / trailing controls
            HStack {
                if config.selectionMode {
                    Button("Cancel", action: config.onCancelSelection)
                        .font(.body.weight(.medium))
                        .foregroundStyle(config.isGlassMode ? Color(.label) : config.tintColor)
                        .padding(.leading, 4)
                        .accessibilityHint("Exits selection mode")
                } else if config.showCloseButton {
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
                    let showShare = config.showShareButton
                    let showEdit  = config.showEditButton
                    let showSel   = config.showSelectButton
                    let visibleCount = [showShare, showEdit, showSel].filter { $0 }.count

                    if visibleCount >= 2 {
                        // Structured identically to CircleButton:
                        //   icon in the label → .buttonStyle(.plain) → CircleButtonBackground
                        // The glass is applied *outside* the label, so Menu's press state
                        // never reaches it — same reason the other buttons have no artifact.
                        Menu {
                            if showShare {
                                Button(action: config.onShare) {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                            }
                            if showEdit {
                                Button(action: config.onEdit) {
                                    Label("Edit", systemImage: "pencil")
                                }
                            }
                            if showSel {
                                Button(action: config.onSelectToggle) {
                                    Label("Select", systemImage: "checkmark")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(config.isGlassMode ? Color(.label) : config.tintColor)
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(.plain)
                        .modifier(CircleButtonBackground(tintColor: config.tintColor, isGlassMode: config.isGlassMode))
                        .accessibilityLabel("More options")
                        .accessibilityHint("Opens a menu with available actions")
                    } else {
                        HStack(spacing: 10) {
                            if showShare {
                                CircleButton(
                                    systemName: "square.and.arrow.up",
                                    accessibilityLabel: "Share",
                                    accessibilityHint: "Shares the current photo",
                                    tintColor: config.tintColor,
                                    isGlassMode: config.isGlassMode,
                                    action: config.onShare
                                )
                            }
                            if showEdit {
                                CircleButton(
                                    systemName: "pencil",
                                    accessibilityLabel: "Edit",
                                    accessibilityHint: "Opens the photo editor",
                                    tintColor: config.tintColor,
                                    isGlassMode: config.isGlassMode,
                                    action: config.onEdit
                                )
                            }
                            if showSel {
                                CircleButton(
                                    systemName: "checkmark",
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
        }
        .padding(.horizontal, 16)
        .padding(.top, compact ? 4 : 12)
        .padding(.bottom, compact ? 4 : 8)
    }
}

// MARK: - Supporting types

struct TopBarConfig {
    var showCloseButton: Bool = true
    var showShareButton: Bool = true
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
    var onDismiss: () -> Void = {}
    var onCancelSelection: () -> Void = {}
    var onSelectToggle: () -> Void = {}
    var onEdit: () -> Void = {}
    var onShare: () -> Void = {}
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
                .foregroundStyle(isGlassMode ? Color(.label) : tintColor)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .modifier(CircleButtonBackground(tintColor: tintColor, isGlassMode: isGlassMode))
        .accessibilityLabel(accessibilityLabel)
        .modifier(OptionalHintModifier(hint: accessibilityHint))
    }
}

/// Applies `.accessibilityHint` only when a non-nil hint is provided,
/// preventing VoiceOver from announcing an empty hint string.
private struct OptionalHintModifier: ViewModifier {
    let hint: String?
    func body(content: Content) -> some View {
        if let hint {
            content.accessibilityHint(hint)
        } else {
            content
        }
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
