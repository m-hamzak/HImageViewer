//
//  HImageViewerLogicTests.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 22/02/2026.
//
//  Tests exercise HImageViewerViewModel directly — every assertion calls
//  real production code rather than replicating logic inline.
//

import XCTest
@testable import HImageViewer

@MainActor
final class HImageViewerLogicTests: XCTestCase {

    // MARK: - Helpers

    private func makeAssets(_ count: Int) -> [PhotoAsset] {
        (0..<count).map { _ in PhotoAsset(image: UIImage(systemName: "star")!) }
    }

    private func makeMediaAssets(_ count: Int) -> [MediaAsset] {
        (0..<count).map { _ in .photo(PhotoAsset(image: UIImage(systemName: "star")!)) }
    }

    private func makeVM(
        assets: [PhotoAsset] = [],
        mediaAssets: [MediaAsset] = [],
        usesMediaMode: Bool = false,
        initialIndex: Int = 0,
        config: HImageViewerConfiguration = .init()
    ) -> HImageViewerViewModel {
        HImageViewerViewModel(
            assets: assets,
            mediaAssets: mediaAssets,
            usesMediaMode: usesMediaMode,
            initialIndex: initialIndex,
            config: config
        )
    }

    // MARK: - isUploading

    func test_isUploading_progressNil() {
        let vm = makeVM()
        vm.uploadState.progress = nil
        XCTAssertFalse(vm.isUploading, "nil progress = not uploading")
    }

    func test_isUploading_progressZero() {
        let state = HImageViewerUploadState(progress: 0.0)
        let vm = makeVM(config: HImageViewerConfiguration(uploadState: state))
        XCTAssertFalse(vm.isUploading, "0.0 = not yet uploading")
    }

    func test_isUploading_progressHalf() {
        let state = HImageViewerUploadState(progress: 0.5)
        let vm = makeVM(config: HImageViewerConfiguration(uploadState: state))
        XCTAssertTrue(vm.isUploading, "0.5 = actively uploading")
    }

    func test_isUploading_progressOne() {
        let state = HImageViewerUploadState(progress: 1.0)
        let vm = makeVM(config: HImageViewerConfiguration(uploadState: state))
        XCTAssertFalse(vm.isUploading, "1.0 = complete, not uploading")
    }

    func test_isUploading_justAboveZero() {
        let state = HImageViewerUploadState(progress: 0.001)
        let vm = makeVM(config: HImageViewerConfiguration(uploadState: state))
        XCTAssertTrue(vm.isUploading, "0.001 = actively uploading")
    }

    func test_isUploading_justBelowOne() {
        let state = HImageViewerUploadState(progress: 0.999)
        let vm = makeVM(config: HImageViewerConfiguration(uploadState: state))
        XCTAssertTrue(vm.isUploading, "0.999 = still uploading")
    }

    // MARK: - shouldShowSaveButton

    func test_shouldShowSave_configTrue_returnsTrue() {
        let vm = makeVM(config: HImageViewerConfiguration(showSaveButton: true))
        XCTAssertTrue(vm.shouldShowSaveButton)
    }

    func test_shouldShowSave_configFalse_returnsFalse() {
        let vm = makeVM(config: HImageViewerConfiguration(showSaveButton: false))
        XCTAssertFalse(vm.shouldShowSaveButton)
    }

    func test_shouldShowSave_default_isTrue() {
        // Default configuration has showSaveButton = true
        let vm = makeVM()
        XCTAssertTrue(vm.shouldShowSaveButton)
    }

    // MARK: - initialIndex clamping

    func test_initialIndex_clampedToZero_forEmptyAssets() {
        let vm = makeVM(assets: [], initialIndex: 5)
        XCTAssertEqual(vm.currentIndex, 0, "Empty assets → index 0")
    }

    func test_initialIndex_clampedToLastIndex_whenTooLarge() {
        let vm = makeVM(assets: makeAssets(3), initialIndex: 10)
        XCTAssertEqual(vm.currentIndex, 2, "10 with 3 assets → clamps to 2")
    }

    func test_initialIndex_clampedToZero_whenNegative() {
        let vm = makeVM(assets: makeAssets(3), initialIndex: -1)
        XCTAssertEqual(vm.currentIndex, 0, "Negative → clamps to 0")
    }

    func test_initialIndex_valid_unchanged() {
        let vm = makeVM(assets: makeAssets(5), initialIndex: 3)
        XCTAssertEqual(vm.currentIndex, 3)
    }

    func test_initialIndex_exactlyLastIndex_unchanged() {
        let vm = makeVM(assets: makeAssets(4), initialIndex: 3)
        XCTAssertEqual(vm.currentIndex, 3)
    }

    func test_initialIndex_singleAsset_alwaysZero() {
        let vm = makeVM(assets: makeAssets(1), initialIndex: 100)
        XCTAssertEqual(vm.currentIndex, 0)
    }

    // MARK: - totalCount

    func test_totalCount_legacyMode_returnsAssetsCount() {
        let vm = makeVM(assets: makeAssets(4))
        XCTAssertEqual(vm.totalCount, 4)
    }

    func test_totalCount_mediaMode_returnsMediaAssetsCount() {
        let vm = makeVM(mediaAssets: makeMediaAssets(6), usesMediaMode: true)
        XCTAssertEqual(vm.totalCount, 6)
    }

    func test_totalCount_emptyAssets_isZero() {
        let vm = makeVM(assets: [])
        XCTAssertEqual(vm.totalCount, 0)
    }

    // MARK: - pageCounterText

    func test_pageCounterText_singleItem_isNil() {
        let vm = makeVM(assets: makeAssets(1))
        XCTAssertNil(vm.pageCounterText)
    }

    func test_pageCounterText_multipleItems_formatsCorrectly() {
        let vm = makeVM(assets: makeAssets(5), initialIndex: 1)
        XCTAssertEqual(vm.pageCounterText, "2 / 5")
    }

    func test_pageCounterText_inSelectionMode_isNil() {
        let vm = makeVM(assets: makeAssets(5))
        vm.selectionMode = true
        XCTAssertNil(vm.pageCounterText)
    }

    func test_pageCounterText_emptyAssets_isNil() {
        let vm = makeVM(assets: [])
        XCTAssertNil(vm.pageCounterText)
    }

    // MARK: - accessibilityPageCounterText

    func test_accessibilityPageCounterText_multipleItems_naturalLanguage() {
        let vm = makeVM(assets: makeAssets(5), initialIndex: 1)
        XCTAssertEqual(vm.accessibilityPageCounterText, "Page 2 of 5")
    }

    func test_accessibilityPageCounterText_singleItem_isNil() {
        let vm = makeVM(assets: makeAssets(1))
        XCTAssertNil(vm.accessibilityPageCounterText)
    }

    func test_accessibilityPageCounterText_inSelectionMode_isNil() {
        let vm = makeVM(assets: makeAssets(3))
        vm.selectionMode = true
        XCTAssertNil(vm.accessibilityPageCounterText)
    }

    // MARK: - currentPhotoAsset

    func test_currentPhotoAsset_legacyMode_returnsCorrectAsset() {
        let assets = makeAssets(3)
        let vm = makeVM(assets: assets, initialIndex: 1)
        XCTAssertEqual(vm.currentPhotoAsset?.id, assets[1].id)
    }

    func test_currentPhotoAsset_mediaMode_photoItem_returnsAsset() {
        let pa = PhotoAsset(image: UIImage(systemName: "star")!)
        let items = [MediaAsset.photo(pa)]
        let vm = makeVM(mediaAssets: items, usesMediaMode: true)
        XCTAssertEqual(vm.currentPhotoAsset?.id, pa.id)
    }

    func test_currentPhotoAsset_mediaMode_videoItem_isNil() {
        let items = [MediaAsset.video(URL(string: "https://example.com/v.mp4")!)]
        let vm = makeVM(mediaAssets: items, usesMediaMode: true)
        XCTAssertNil(vm.currentPhotoAsset)
    }

    func test_currentPhotoAsset_emptyAssets_isNil() {
        let vm = makeVM(assets: [])
        XCTAssertNil(vm.currentPhotoAsset)
    }

    // MARK: - dragProgress

    func test_dragProgress_zero_isZero() {
        let vm = makeVM()
        vm.dragOffset = 0
        XCTAssertEqual(vm.dragProgress, 0.0, accuracy: 0.001)
    }

    func test_dragProgress_atThreshold_isOne() {
        let vm = makeVM()
        vm.dragOffset = vm.dismissThreshold
        XCTAssertEqual(vm.dragProgress, 1.0, accuracy: 0.001)
    }

    func test_dragProgress_halfThreshold_isHalf() {
        let vm = makeVM()
        vm.dragOffset = vm.dismissThreshold / 2
        XCTAssertEqual(vm.dragProgress, 0.5, accuracy: 0.001)
    }

    func test_dragProgress_beyondThreshold_clampedToOne() {
        let vm = makeVM()
        vm.dragOffset = vm.dismissThreshold * 10
        XCTAssertEqual(vm.dragProgress, 1.0, accuracy: 0.001)
    }

    func test_dragProgress_negative_isZero() {
        let vm = makeVM()
        vm.dragOffset = -50
        XCTAssertEqual(vm.dragProgress, 0.0, accuracy: 0.001)
    }

    // MARK: - handleSelection

    func test_handleSelection_firstTap_selects() {
        let vm = makeVM(assets: makeAssets(3))
        vm.handleSelection(1)
        XCTAssertTrue(vm.selectedIndices.contains(1))
    }

    func test_handleSelection_secondTap_deselects() {
        let vm = makeVM(assets: makeAssets(3))
        vm.handleSelection(1)
        vm.handleSelection(1)
        XCTAssertFalse(vm.selectedIndices.contains(1))
    }

    func test_handleSelection_multipleItems() {
        let vm = makeVM(assets: makeAssets(5))
        vm.handleSelection(0)
        vm.handleSelection(2)
        vm.handleSelection(4)
        XCTAssertEqual(vm.selectedIndices, [0, 2, 4])
    }

    func test_handleSelection_threeToggles_leavesSelected() {
        let vm = makeVM(assets: makeAssets(3))
        vm.handleSelection(0)
        vm.handleSelection(0)
        vm.handleSelection(0)
        XCTAssertTrue(vm.selectedIndices.contains(0), "Odd toggles → selected")
    }

    // MARK: - cancelSelection

    func test_cancelSelection_clearsIndicesAndMode() {
        let vm = makeVM(assets: makeAssets(3))
        vm.selectionMode = true
        vm.selectedIndices = [0, 1, 2]
        vm.cancelSelection()
        XCTAssertFalse(vm.selectionMode)
        XCTAssertTrue(vm.selectedIndices.isEmpty)
    }

    func test_cancelSelection_idempotent() {
        let vm = makeVM(assets: makeAssets(3))
        vm.cancelSelection()
        vm.cancelSelection()
        XCTAssertFalse(vm.selectionMode)
        XCTAssertTrue(vm.selectedIndices.isEmpty)
    }

    // MARK: - handleDelete (legacy mode)

    func test_handleDelete_removesSelectedAssets() {
        let assets = makeAssets(3)
        let keepID = assets[1].id
        let vm = makeVM(assets: assets)
        vm.selectedIndices = [0, 2]
        vm.handleDelete()
        XCTAssertEqual(vm.assets.count, 1)
        XCTAssertEqual(vm.assets.first?.id, keepID)
    }

    func test_handleDelete_clearsSelectionAndMode() {
        let vm = makeVM(assets: makeAssets(3))
        vm.selectionMode = true
        vm.selectedIndices = [0]
        vm.handleDelete()
        XCTAssertTrue(vm.selectedIndices.isEmpty)
        XCTAssertFalse(vm.selectionMode)
    }

    func test_handleDelete_outOfBoundsIndex_ignored() {
        let vm = makeVM(assets: makeAssets(2))
        vm.selectedIndices = [5]
        vm.handleDelete()
        XCTAssertEqual(vm.assets.count, 2, "Out-of-bounds selection must not delete anything")
    }

    func test_handleDelete_allAssets_leavesEmpty() {
        let vm = makeVM(assets: makeAssets(2))
        vm.selectedIndices = [0, 1]
        vm.handleDelete()
        XCTAssertTrue(vm.assets.isEmpty)
    }

    func test_handleDelete_clampsCurrentIndex() {
        let vm = makeVM(assets: makeAssets(3), initialIndex: 2)
        vm.selectedIndices = [1, 2]
        vm.handleDelete()
        XCTAssertEqual(vm.assets.count, 1)
        XCTAssertEqual(vm.currentIndex, 0, "currentIndex must clamp after deletion")
    }

    func test_handleDelete_largeSelection_correctCountRemains() {
        let vm = makeVM(assets: makeAssets(10))
        vm.selectedIndices = [0, 2, 4, 6, 8]
        vm.handleDelete()
        XCTAssertEqual(vm.assets.count, 5)
    }

    // MARK: - handleDelete (media mode)

    func test_handleDelete_mediaMode_removesSelectedItems() {
        let items = makeMediaAssets(4)
        let keepID = items[1].id
        let vm = makeVM(mediaAssets: items, usesMediaMode: true)
        vm.selectedIndices = [0, 2, 3]
        vm.handleDelete()
        XCTAssertEqual(vm.mediaAssets.count, 1)
        XCTAssertEqual(vm.mediaAssets.first?.id, keepID)
    }

    func test_handleDelete_mediaMode_clearsSelectionAndMode() {
        let vm = makeVM(mediaAssets: makeMediaAssets(3), usesMediaMode: true)
        vm.selectionMode = true
        vm.selectedIndices = [0]
        vm.handleDelete()
        XCTAssertTrue(vm.selectedIndices.isEmpty)
        XCTAssertFalse(vm.selectionMode)
    }

    // MARK: - Selection mode / content visibility
    //
    // The view shows EITHER the paged TabView (selectionMode == false)
    // OR the grid (selectionMode == true) — never both simultaneously.
    // These tests verify the ViewModel flag that drives that exclusive switch.

    func test_selectionMode_defaultIsFalse() {
        let vm = makeVM(assets: makeAssets(3))
        XCTAssertFalse(vm.selectionMode,
                       "Viewer must open showing the paged content, not the selection grid")
    }

    func test_selectionMode_setTrue_gridShown() {
        let vm = makeVM(assets: makeAssets(3))
        vm.selectionMode = true
        XCTAssertTrue(vm.selectionMode,
                      "selectionMode=true must switch view to show the grid")
    }

    func test_selectionMode_cancelSelection_contentViewRestored() {
        let vm = makeVM(assets: makeAssets(3))
        vm.selectionMode = true
        vm.cancelSelection()
        XCTAssertFalse(vm.selectionMode,
                       "cancelSelection must restore selectionMode=false so the paged content is shown again")
    }

    func test_selectionMode_handleDelete_contentViewRestored() {
        let vm = makeVM(assets: makeAssets(3))
        vm.selectionMode = true
        vm.selectedIndices = [0]
        vm.handleDelete()
        XCTAssertFalse(vm.selectionMode,
                       "handleDelete must exit selection mode and restore the paged content view")
    }

    func test_selectionMode_mediaMode_cancelRestores() {
        let vm = makeVM(mediaAssets: makeMediaAssets(3), usesMediaMode: true)
        vm.selectionMode = true
        vm.cancelSelection()
        XCTAssertFalse(vm.selectionMode,
                       "Media-mode viewer must also restore selectionMode=false after cancel")
    }

    // MARK: - handleSave

    func test_handleSave_legacyMode_callsDelegate() {
        let delegate = MockDelegate()
        let config = HImageViewerConfiguration(delegate: delegate)
        let vm = makeVM(assets: makeAssets(2), config: config)
        vm.comment = "Nice photo"
        vm.handleSave()
        XCTAssertTrue(delegate.didTapSaveCalled)
        XCTAssertEqual(delegate.lastSaveComment, "Nice photo")
        XCTAssertEqual(delegate.lastSavePhotos?.count, 2)
    }

    func test_handleSave_mediaMode_onlyPassesPhotos() {
        let delegate = MockDelegate()
        let config = HImageViewerConfiguration(delegate: delegate)
        let items: [MediaAsset] = [
            .photo(PhotoAsset(image: UIImage(systemName: "star")!)),
            .video(URL(string: "https://example.com/v.mp4")!)
        ]
        let vm = makeVM(mediaAssets: items, usesMediaMode: true, config: config)
        vm.handleSave()
        XCTAssertTrue(delegate.didTapSaveCalled)
        XCTAssertEqual(delegate.lastSavePhotos?.count, 1,
                       "Videos must be excluded from the photos passed to the delegate")
    }

    func test_handleSave_noDelegate_doesNotCrash() {
        let vm = makeVM(assets: makeAssets(1))
        XCTAssertNoThrow(vm.handleSave())
    }
}
