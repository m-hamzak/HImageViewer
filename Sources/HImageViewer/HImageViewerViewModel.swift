//
//  HImageViewerViewModel.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 20/04/2026.
//

import Combine
import SwiftUI

/// Holds all mutable state and business logic for `HImageViewer`.
///
/// `HImageViewer` is a thin SwiftUI view that binds to this object.
/// Keeping the logic here makes it directly unit-testable without rendering.
@MainActor
final class HImageViewerViewModel: ObservableObject {

    // MARK: - Item collection

    /// The unified media items displayed by the viewer.
    @Published var mediaAssets: [MediaAsset]

    // MARK: - View state

    @Published var isShareSheetPresented: Bool = false
    @Published var shareItems: [Any] = []

    @Published var currentIndex: Int {
        didSet {
            guard currentIndex != oldValue else { return }
            delegate?.didChangePage(to: currentIndex)
            if config.pageChangeHaptic { haptics.selection() }
        }
    }
    @Published var selectionMode: Bool = false
    @Published var selectedIndices: Set<Int> = []
    @Published var comment: String
    @Published var dragOffset: CGFloat = 0

    // MARK: - Dependencies

    let config: HImageViewerConfiguration
    let uploadState: HImageViewerUploadState
    weak var delegate: HImageViewerControlDelegate?
    let haptics: HapticFeedbackProviding
    private var uploadStateCancellable: AnyCancellable?

    let dismissThreshold: CGFloat = 120

    // MARK: - Init

    init(
        mediaAssets: [MediaAsset] = [],
        initialIndex: Int = 0,
        config: HImageViewerConfiguration = .init(),
        haptics: HapticFeedbackProviding = HapticFeedbackProvider()
    ) {
        self.mediaAssets = mediaAssets
        self.config = config
        self.comment = config.initialComment ?? ""
        self.delegate = config.delegate
        self.uploadState = config.uploadState ?? HImageViewerUploadState()
        self.haptics = haptics

        let count = mediaAssets.count
        self.currentIndex = count == 0 ? 0 : max(0, min(initialIndex, count - 1))

        // Forward uploadState changes into the VM's own objectWillChange so
        // HImageViewer re-renders whenever progress updates.
        uploadStateCancellable = self.uploadState.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
    }

    // MARK: - Computed properties

    /// `true` while an upload is actively in progress (progress > 0 and < 1).
    var isUploading: Bool {
        let p = uploadState.progress ?? 0
        return p > 0 && p < 1.0
    }

    /// Whether the Save button should be visible.
    var shouldShowSaveButton: Bool {
        config.showSaveButton
    }

    /// Total number of items.
    var totalCount: Int {
        mediaAssets.count
    }

    /// The `PhotoAsset` at the current page, or `nil` when viewing a video.
    var currentPhotoAsset: PhotoAsset? {
        mediaAssets[safe: currentIndex]?.photoAsset
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
        haptics.impact(.medium)
    }

    /// Exits selection mode and clears all selected indices.
    func cancelSelection() {
        selectionMode = false
        selectedIndices.removeAll()
        haptics.impact(.light)
    }

    // MARK: - Delete

    /// Removes all currently selected items and exits selection mode.
    func handleDelete() {
        guard !selectedIndices.isEmpty else { return }
        let deletedAssets = selectedIndices.compactMap { mediaAssets[safe: $0] }
        let deletedIDs = Set(deletedAssets.map(\.id))
        mediaAssets.removeAll { deletedIDs.contains($0.id) }
        selectedIndices.removeAll()
        selectionMode = false
        if !mediaAssets.isEmpty {
            currentIndex = min(currentIndex, mediaAssets.count - 1)
        }
        delegate?.didDeleteMediaAssets(deletedAssets)
        haptics.impact(.heavy)
    }

    // MARK: - Reorder

    /// Moves the item at `fromIndex` to `toIndex`, clearing the current selection.
    ///
    /// No-ops when either index is out of bounds or both indices are equal.
    func reorderItems(from fromIndex: Int, to toIndex: Int) {
        guard fromIndex != toIndex else { return }
        guard fromIndex >= 0, toIndex >= 0,
              fromIndex < mediaAssets.count, toIndex < mediaAssets.count else { return }
        mediaAssets.move(
            fromOffsets: IndexSet(integer: fromIndex),
            toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
        )
        selectedIndices.removeAll()
    }

    // MARK: - Save

    /// Notifies the delegate with the current comment and all photos.
    func handleSave() {
        let photos = mediaAssets.compactMap(\.photoAsset)
        delegate?.didTapSaveButton(comment: comment, photos: photos)
        haptics.impact(.medium)
    }

    // MARK: - Share

    /// Gathers shareable images and presents the system share sheet.
    ///
    /// In selection mode every selected photo is included; otherwise only the
    /// current photo. Falls back to all photos when the current item is a video.
    func handleShare() {
        let photos: [PhotoAsset]
        if selectionMode, !selectedIndices.isEmpty {
            photos = selectedIndices.sorted().compactMap { mediaAssets[safe: $0]?.photoAsset }
        } else if let current = currentPhotoAsset {
            photos = [current]
        } else {
            photos = mediaAssets.compactMap(\.photoAsset)
        }

        delegate?.didTapShareButton(photos: photos)

        let images = photos.compactMap(\.image)
        guard !images.isEmpty else { return }
        shareItems = images
        isShareSheetPresented = true
        haptics.impact(.light)
    }
}
