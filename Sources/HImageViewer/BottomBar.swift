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
        VStack {
            Divider()
            HStack {
                if config.isSinglePhotoMode {
                    textSection
                }
                    Spacer()

                if config.showSaveButton {
                    Button(action: {
                        if config.selectionMode {
                            config.onDelete()
                        } else {
                            config.onSave()
                        }
                    }) {
                        Text(config.selectionMode ? "Remove" : "Save")
                            .bold()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.gray)
                    .padding(.trailing)
                    .padding(.bottom, 16)
                }
            }
        }
    }

    @ViewBuilder
    private var textSection: some View {
        if config.showCommentBox {
            TextField("Add a comment...", text: $comment)
                .textFieldStyle(.roundedBorder)
                .padding([.horizontal, .bottom])
                .frame(minHeight: 50)
        } else if let title = config.title {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
                .padding(.vertical, 8)
        }
    }
}

// MARK: - Supporting types

struct BottomBarConfig {
    var isSinglePhotoMode: Bool
    var selectionMode: Bool
    var showSaveButton: Bool
    var showCommentBox: Bool
    var title: String?
    var onSave: () -> Void
    var onDelete: () -> Void
}

