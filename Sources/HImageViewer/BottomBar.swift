//
//  BottomBar.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 09/07/2025.
//

import SwiftUI

struct BottomBar: View {
    @Binding var comment: String
    let config: BottomBarConfig

    var body: some View {
        if config.isGlassMode {
            glassBar
        } else {
            classicBar
        }
    }

    // MARK: - Glass style (default iOS 26 theme)

    private var glassBar: some View {
        HStack(alignment: .center, spacing: 12) {
            glassTextSection
            if config.showSaveButton {
                glassActionButton
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassRoundedRect(cornerRadius: 22)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var glassTextSection: some View {
        if config.showCommentBox {
            TextField("Add a comment…", text: $comment)
                .textFieldStyle(.plain)
                .foregroundStyle(.primary)
                .tint(config.tintColor)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Comment")
                .accessibilityHint("Enter a comment to save with the photo")
        } else if let title = config.title {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
        } else {
            Spacer()
        }
    }

    private var glassActionButton: some View {
        Button {
            config.selectionMode ? config.onDelete() : config.onSave()
        } label: {
            Text(config.selectionMode ? "Remove" : "Save")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 9)
                .background(Capsule().fill(config.tintColor))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(config.selectionMode ? "Remove selected items" : "Save photo")
        .accessibilityHint(config.selectionMode ? "Deletes the selected photos" : "Saves the photo and comment")
    }

    // MARK: - Classic style (when tintColor is provided)

    private var classicBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                classicTextSection
                Spacer()
                if config.showSaveButton {
                    Button {
                        config.selectionMode ? config.onDelete() : config.onSave()
                    } label: {
                        Text(config.selectionMode ? "Remove" : "Save")
                            .bold()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(config.tintColor)
                    .padding(.trailing)
                    .padding(.bottom, 16)
                    .accessibilityLabel(config.selectionMode ? "Remove selected items" : "Save photo")
                    .accessibilityHint(config.selectionMode ? "Deletes the selected photos" : "Saves the photo and comment")
                }
            }
        }
    }

    @ViewBuilder
    private var classicTextSection: some View {
        if config.showCommentBox {
            TextField("Add a comment…", text: $comment)
                .textFieldStyle(.roundedBorder)
                .padding([.horizontal, .bottom])
                .frame(minHeight: 50)
                .accessibilityLabel("Comment")
                .accessibilityHint("Enter a comment to save with the photo")
        } else if let title = config.title {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .accessibilityAddTraits(.isHeader)
        }
    }
}

// MARK: - Supporting types

struct BottomBarConfig {
    var selectionMode: Bool
    var showSaveButton: Bool
    var showCommentBox: Bool
    var title: String?
    /// Accent color for the action button. Used in classic mode; also tints the text cursor in glass mode.
    var tintColor: Color = .blue
    /// `true` = iOS 26 Liquid Glass style; `false` = classic bordered style.
    var isGlassMode: Bool = true
    var onSave: () -> Void
    var onDelete: () -> Void
}
