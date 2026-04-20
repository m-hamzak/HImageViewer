//
//  MultiPhotoGrid.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 21/04/2025.
//

import SwiftUI
import Photos

/// A scrollable grid of thumbnail tiles shown in selection mode.
///
/// Each tile displays a photo thumbnail (via `PhotoView`) or a video placeholder icon.
/// A checkmark overlay appears on top of selected tiles.
public struct MultiPhotoGrid: View {

    // MARK: - Properties

    let mediaItems: [MediaAsset]
    let selectedIndices: Set<Int>
    let selectionMode: Bool
    let onSelectToggle: (Int) -> Void

    let itemSize: CGFloat = 110

    // MARK: - Body

    public var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: itemSize), spacing: 10)],
            spacing: 10
        ) {
            ForEach(Array(mediaItems.enumerated()), id: \.1.id) { index, item in
                ZStack(alignment: .topTrailing) {
                    thumbnailView(for: item)
                        .frame(width: itemSize, height: itemSize)
                        .cornerRadius(12)

                    if selectionMode {
                        Button {
                            onSelectToggle(index)
                        } label: {
                            Image(
                                systemName: selectedIndices.contains(index)
                                    ? "checkmark.circle.fill"
                                    : "circle"
                            )
                            .font(.system(size: 20))
                            .foregroundColor(
                                selectedIndices.contains(index) ? .blue : .gray
                            )
                            .padding(4)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func thumbnailView(for item: MediaAsset) -> some View {
        switch item.kind {
        case .photo(let asset):
            PhotoView(photo: asset, isSinglePhotoMode: false)

        case .video:
            ZStack {
                Color.black.opacity(0.85)
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }
}
