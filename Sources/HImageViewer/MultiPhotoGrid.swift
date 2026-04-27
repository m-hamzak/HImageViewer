//
//  MultiPhotoGrid.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 21/04/2025.
//

import SwiftUI
import Photos
import UniformTypeIdentifiers

/// A scrollable grid of thumbnail tiles shown in selection mode.
///
/// Each tile displays a photo thumbnail (via `PhotoView`) or a video placeholder icon.
/// A checkmark overlay appears on top of selected tiles. Long-press and drag any tile
/// to reorder items within the grid.
struct MultiPhotoGrid: View {

    // MARK: - Properties

    let mediaItems: [MediaAsset]
    let selectedIndices: Set<Int>
    let selectionMode: Bool
    let onSelectToggle: (Int) -> Void
    /// Called with `(fromIndex, toIndex)` whenever a drag-to-reorder completes.
    /// `nil` disables reordering (default, backward-compatible).
    var onReorder: ((Int, Int) -> Void)? = nil
    /// When non-nil, the grid scrolls this item into view on appear.
    /// Pass the viewer's `currentIndex` so entering selection mode reveals the current photo.
    var focusIndex: Int? = nil

    let itemSize: CGFloat = 110

    @State private var draggingIndex: Int? = nil

    // MARK: - Body

    var body: some View {
        ScrollViewReader { proxy in
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: itemSize), spacing: 10)],
                spacing: 10
            ) {
            ForEach(Array(mediaItems.enumerated()), id: \.1.id) { index, item in
                let label = MultiPhotoGrid.tileLabel(for: item, at: index)
                ZStack(alignment: .topTrailing) {
                    thumbnailView(for: item)
                        .frame(width: itemSize, height: itemSize)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    if selectionMode {
                        // Visual indicator only — the tap is on the whole tile below.
                        Image(
                            systemName: selectedIndices.contains(index)
                                ? "checkmark.circle.fill"
                                : "circle"
                        )
                        .font(.system(size: 20))
                        .foregroundColor(
                            selectedIndices.contains(index) ? .blue : .white
                        )
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .padding(6)
                    }
                }
                // The entire tile is the tap target so the user doesn't have to
                // precisely hit the small corner circle (matches iOS Photos behaviour).
                .contentShape(Rectangle())
                .onTapGesture { if selectionMode { onSelectToggle(index) } }
                .accessibilityLabel(label)
                .accessibilityAddTraits(.isImage)
                .accessibilityValue(selectionMode
                    ? (selectedIndices.contains(index) ? "Selected" : "Not selected")
                    : "")
                .accessibilityHint(selectionMode ? "Tap to toggle selection" : "")
                // Dim the tile that is currently being dragged.
                .opacity(draggingIndex == index ? 0.5 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: draggingIndex)
                // Drag source — long-press activates automatically.
                .onDrag {
                    draggingIndex = index
                    return NSItemProvider(object: "\(index)" as NSString)
                }
                // Drop target — each tile accepts a drop from any other tile.
                .onDrop(
                    of: [UTType.text],
                    delegate: GridDropDelegate(
                        targetIndex: index,
                        draggingIndex: $draggingIndex,
                        onReorder: onReorder
                    )
                )
            }
        }
        .padding(.horizontal)
        .padding(.top)
        .onAppear {
            guard let focus = focusIndex else { return }
            // Defer one run-loop cycle so the grid has finished layout before scrolling.
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(mediaItems[safe: focus]?.id, anchor: .center)
                }
            }
        }
        } // ScrollViewReader
    }

    // MARK: - Helpers

    /// Returns the VoiceOver label for a grid tile, e.g. `"Photo 1"` or `"Video 3"`.
    static func tileLabel(for item: MediaAsset, at index: Int) -> String {
        item.isPhoto ? "Photo \(index + 1)" : "Video \(index + 1)"
    }

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

// MARK: - Drop Delegate

/// Handles live tile swapping as the user drags across the grid.
private struct GridDropDelegate: DropDelegate {

    let targetIndex: Int
    @Binding var draggingIndex: Int?
    let onReorder: ((Int, Int) -> Void)?

    /// Fires continuously as the dragged tile hovers over this tile — performs live swap.
    func dropEntered(info: DropInfo) {
        guard let from = draggingIndex, from != targetIndex else { return }
        onReorder?(from, targetIndex)
        draggingIndex = targetIndex
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingIndex = nil
        return true
    }
}
