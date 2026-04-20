//
//  HImageViewerViewModel.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 20/04/2026.
//

import SwiftUI

/// Holds all mutable state and business logic for `HImageViewer`.
///
/// `HImageViewer` is a thin SwiftUI view that binds to this object.
/// Keeping the logic here makes it directly unit-testable without rendering.
@MainActor
final class HImageViewerViewModel: ObservableObject {

    // MARK: - Item collections

    /// Photo assets in legacy (photo-only) mode.
    @Published var assets: [PhotoAsset]

    /// Mixed-media assets in media mode.
    @Published var mediaAssets: [MediaAsset]

    /// `true` when the viewer was created with `init(mediaAssets:)`.
    let usesMediaMode: Bool

    /// Video URL shown in legacy mode when `selectedVideo` is non-nil.
    let selectedVideo: URL?

    // MARK: - View state

    @Published var currentIndex: Int
    @Published var selectionMode: Bool = false
    @Published var selectedIndices: Set<Int> = []
    @Published var comment: String
    @Published var wasImageEdited: Bool = false
    @Published var dragOffset: CGFloat = 0

    // MARK: - Dependencies

    let config: HImageViewerConfiguration
    let uploadState: HImageViewerUploadState
    weak var delegate: HImageViewerControlDelegate?

    let dismissThreshold: CGFloat = 120

    // MARK: - Init

    init(
        assets: [PhotoAsset] = [],
        mediaAssets: [MediaAsset] = [],
        selectedVideo: URL? = nil,
        usesMediaMode: Bool,
        initialIndex: Int = 0,
        config: HImageViewerConfiguration = .init()
    ) {
        self.assets = assets
        self.mediaAssets = mediaAssets
        self.selectedVideo = selectedVideo
        self.usesMediaMode = usesMediaMode
        self.config = config
        self.comment = config.initialComment ?? ""
        self.delegate = config.delegate
        self.uploadState = config.uploadState ?? HImageViewerUploadState()

        let count = usesMediaMode ? mediaAssets.count : assets.count
        let clamped = count == 0 ? 0 : max(0, min(initialIndex, count - 1))
        self.currentIndex = clamped
    }

    // MARK: - Computed properties

    /// `true` while an upload is actively in progress (progress > 0 and < 1).
    var isUploading: Bool {
        (uploadState.progress ?? 0) > 0 && (uploadState.progress ?? 0) < 1.0
    }

    /// Whether the Save button should be visible.
    var shouldShowSaveButton: Bool {
        wasImageEdited || config.showSaveButton
    }

    /// Total number of items across both modes.
    var totalCount: Int {
        usesMediaMode ? mediaAssets.count : assets.count
    }

    /// The `PhotoAsset` at the current page, or `nil` when viewing a video.
    var currentPhotoAsset: PhotoAsset? {
        if usesMediaMode {
            return mediaAssets[safe: currentIndex]?.photoAsset
        }
        return assets[safe: currentIndex]
    }

    /// `"2 / 5"` for the TopBar counter label; `nil` in single-item or selection mode.
    var pageCounterText: String? {
        guard totalCount > 1, !selectionMode else { return nil }
        return "\(currentIndex + 1) / \(totalCount)"
    }

    /// Natural-language page counter for VoiceOver, e.g. `"Page 2 of 5"`.
    var accessibilityPageCounterText: String? {
        guard totalCount > 1, !selectionMode else { return nil }
        return "Page \(currentIndex + 1) of \(totalCount)"
    }

    /// 0→1 progress of the drag towards the dismiss threshold.
    var dragProgress: Double {
        min(Double(max(0, dragOffset)) / Double(dismissThreshold), 1.0)
    }

    // MARK: - Selection

    /// Toggles the selection state of the item at `index`.
    func handleSelection(_ index: Int) {
        if selectedIndices.contains(index) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.insert(index)
        }
    }

    /// Exits selection mode and clears all selected indices.
    func cancelSelection() {
        selectionMode = false
        selectedIndices.removeAll()
    }

    // MARK: - Delete

    /// Removes all currently selected items and exits selection mode.
    func handleDelete() {
        if usesMediaMode {
            let deletedIDs = Set(selectedIndices.compactMap { mediaAssets[safe: $0]?.id })
            mediaAssets.removeAll { deletedIDs.contains($0.id) }
            selectedIndices.removeAll()
            selectionMode = false
            if !mediaAssets.isEmpty {
                currentIndex = min(currentIndex, mediaAssets.count - 1)
            }
        } else {
            let deletedAssets = selectedIndices
                .filter { $0 < assets.count }
                .compactMap { assets[safe: $0] }
            assets.removeAll { asset in
                deletedAssets.contains(where: { $0.id == asset.id })
            }
            selectedIndices.removeAll()
            selectionMode = false
            if !assets.isEmpty {
                currentIndex = min(currentIndex, assets.count - 1)
            }
        }
    }

    // MARK: - Save

    /// Notifies the delegate with the current comment and all photos.
    func handleSave() {
        if usesMediaMode {
            let photos = mediaAssets.compactMap(\.photoAsset)
            delegate?.didTapSaveButton(comment: comment, photos: photos)
        } else {
            delegate?.didTapSaveButton(comment: comment, photos: assets)
        }
    }
}
