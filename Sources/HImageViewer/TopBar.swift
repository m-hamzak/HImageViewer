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
            if !config.selectionMode {
                CircleButton(systemName: "xmark", action: config.onDismiss)
            }
            Spacer()
            if config.isSinglePhotoMode {
                CircleButton(systemName: "pencil", action: config.onEdit)
            } else {
                Button(config.selectionMode ? "Done" : "Select", action: config.onSelectToggle)
                    .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }
}

// MARK: - Supporting types

struct TopBarConfig {
    var isSinglePhotoMode: Bool
    var selectionMode: Bool
    var onDismiss: () -> Void
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
