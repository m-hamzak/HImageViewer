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
        HStack {
            if config.selectionMode {
                Button("Cancel", action: config.onCancelSelection)
                    .foregroundStyle(.primary)
                    .padding(.leading, 4)
            } else {
                CircleButton(systemName: "xmark", action: config.onDismiss)
            }
            Spacer()
            if config.isSinglePhotoMode && !config.selectionMode {
                if config.showEditButton {
                    CircleButton(systemName: "pencil", action: config.onEdit)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }
}

// MARK: - Supporting types

struct TopBarConfig {
    var isSinglePhotoMode: Bool
    var showEditButton: Bool
    var selectionMode: Bool
    var onDismiss: () -> Void
    var onCancelSelection: () -> Void
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
