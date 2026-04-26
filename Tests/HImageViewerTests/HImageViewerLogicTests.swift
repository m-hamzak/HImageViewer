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

    private func makeMediaAssets(_ count: Int) -> [MediaAsset] {
        (0..<count).map { _ in .photo(PhotoAsset(image: UIImage(systemName: "star")!)) }
    }

    private func makeVM(
        mediaAssets: [MediaAsset] = [],
        initialIndex: Int = 0,
        config: HImageViewerConfiguration = .init()
    ) -> HImageViewerViewModel {
        HImageViewerViewModel(
            mediaAssets: mediaAssets,
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

    func test_uploadState_progressChange_triggersVMObjectWillChange() {
        // Verifies that the VM forwards uploadState.objectWillChange so SwiftUI
        // re-renders HImageViewer whenever progress updates.
        let state = HImageViewerUploadState()
        let vm = makeVM(config: HImageViewerConfiguration(uploadState: state))

        let expectation = XCTestExpectation(description: "VM objectWillChange fires on progress update")
        let cancellable = vm.objectWillChange.sink { expectation.fulfill() }

        state.progress = 0.5

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(vm.uploadState.progress, 0.5)
        _ = cancellable // retain
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
        let vm = makeVM()
        XCTAssertTrue(vm.shouldShowSaveButton)
    }

    // MARK: - initialIndex clamping

    func test_initialIndex_clampedToZero_forEmptyAssets() {
        let vm = makeVM(mediaAssets: [], initialIndex: 5)
        XCTAssertEqual(vm.currentIndex, 0, "Empty assets → index 0")
    }

    func test_initialIndex_clampedToLastIndex_whenTooLarge() {
        let vm = makeVM(mediaAssets: makeMediaAssets(3), initialIndex: 10)
        XCTAssertEqual(vm.currentIndex, 2, "10 with 3 assets → clamps to 2")
    }

    func test_initialIndex_clampedToZero_whenNegative() {
        let vm = makeVM(mediaAssets: makeMediaAssets(3), initialIndex: -1)
        XCTAssertEqual(vm.currentIndex, 0, "Negative → clamps to 0")
    }

    func test_initialIndex_valid_unchanged() {
        let vm = makeVM(mediaAssets: makeMediaAssets(5), initialIndex: 3)
        XCTAssertEqual(vm.currentIndex, 3)
    }

    func test_initialIndex_exactlyLastIndex_unchanged() {
        let vm = makeVM(mediaAssets: makeMediaAssets(4), initialIndex: 3)
        XCTAssertEqual(vm.currentIndex, 3)
    }

    func test_initialIndex_singleAsset_alwaysZero() {
        let vm = makeVM(mediaAssets: makeMediaAssets(1), initialIndex: 100)
        XCTAssertEqual(vm.currentIndex, 0)
    }

    // MARK: - totalCount

    func test_totalCount_returnsMediaAssetsCount() {
        let vm = makeVM(mediaAssets: makeMediaAssets(4))
        XCTAssertEqual(vm.totalCount, 4)
    }

    func test_totalCount_emptyAssets_isZero() {
        let vm = makeVM(mediaAssets: [])
        XCTAssertEqual(vm.totalCount, 0)
    }

    func test_totalCount_mixedPhotoAndVideo() {
        let items: [MediaAsset] = [
            .photo(PhotoAsset(image: UIImage(systemName: "star")!)),
            .video(URL(string: "https://example.com/v.mp4")!)
        ]
        let vm = makeVM(mediaAssets: items)
        XCTAssertEqual(vm.totalCount, 2)
    }

    // MARK: - pageCounterText

    func test_pageCounterText_singleItem_isNil() {
        let vm = makeVM(mediaAssets: makeMediaAssets(1))
        XCTAssertNil(vm.pageCounterText)
    }

    func test_pageCounterText_multipleItems_formatsCorrectly() {
        let vm = makeVM(mediaAssets: makeMediaAssets(5), initialIndex: 1)
        XCTAssertEqual(vm.pageCounterText, "2 / 5")
    }

    func test_pageCounterText_inSelectionMode_isNil() {
        let vm = makeVM(mediaAssets: makeMediaAssets(5))
        vm.selectionMode = true
        XCTAssertNil(vm.pageCounterText)
    }

    func test_pageCounterText_emptyAssets_isNil() {
        let vm = makeVM(mediaAssets: [])
        XCTAssertNil(vm.pageCounterText)
    }

    // MARK: - accessibilityPageCounterText

    func test_accessibilityPageCounterText_multipleItems_naturalLanguage() {
        let vm = makeVM(mediaAssets: makeMediaAssets(5), initialIndex: 1)
        XCTAssertEqual(vm.accessibilityPageCounterText, "Page 2 of 5")
    }

    func test_accessibilityPageCounterText_singleItem_isNil() {
        let vm = makeVM(mediaAssets: makeMediaAssets(1))
        XCTAssertNil(vm.accessibilityPageCounterText)
    }

    func test_accessibilityPageCounterText_inSelectionMode_isNil() {
        let vm = makeVM(mediaAssets: makeMediaAssets(3))
        vm.selectionMode = true
        XCTAssertNil(vm.accessibilityPageCounterText)
    }

    // MARK: - currentPhotoAsset

    func test_currentPhotoAsset_photoItem_returnsAsset() {
        let pa = PhotoAsset(image: UIImage(systemName: "star")!)
        let vm = makeVM(mediaAssets: [.photo(pa)])
        XCTAssertEqual(vm.currentPhotoAsset?.id, pa.id)
    }

    func test_currentPhotoAsset_videoItem_isNil() {
        let items = [MediaAsset.video(URL(string: "https://example.com/v.mp4")!)]
        let vm = makeVM(mediaAssets: items)
        XCTAssertNil(vm.currentPhotoAsset)
    }

    func test_currentPhotoAsset_emptyAssets_isNil() {
        let vm = makeVM(mediaAssets: [])
        XCTAssertNil(vm.currentPhotoAsset)
    }

    func test_currentPhotoAsset_atNonZeroIndex_returnsCorrectAsset() {
        let pa = PhotoAsset(image: UIImage(systemName: "heart")!)
        let items: [MediaAsset] = [
            .photo(PhotoAsset(image: UIImage(systemName: "star")!)),
            .photo(pa)
        ]
        let vm = makeVM(mediaAssets: items, initialIndex: 1)
        XCTAssertEqual(vm.currentPhotoAsset?.id, pa.id)
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
        let vm = makeVM(mediaAssets: makeMediaAssets(3))
        vm.handleSelection(1)
        XCTAssertTrue(vm.selectedIndices.contains(1))
    }

    func test_handleSelection_secondTap_deselects() {
        let vm = makeVM(mediaAssets: makeMediaAssets(3))
        vm.handleSelection(1)
        vm.handleSelection(1)
        XCTAssertFalse(vm.selectedIndices.contains(1))
    }

    func test_handleSelection_multipleItems() {
        let vm = makeVM(mediaAssets: makeMediaAssets(5))
        vm.handleSelection(0)
        vm.handleSelection(2)
        vm.handleSelection(4)
        XCTAssertEqual(vm.selectedIndices, [0, 2, 4])
    }

    func test_handleSelection_threeToggles_leavesSelected() {
        let vm = makeVM(mediaAssets: makeMediaAssets(3))
        vm.handleSelection(0)
        vm.handleSelection(0)
        vm.handleSelection(0)
        XCTAssertTrue(vm.selectedIndices.contains(0), "Odd toggles → selected")
    }

    // MARK: - cancelSelection

    func test_cancelSelection_clearsIndicesAndMode() {
        let vm = makeVM(mediaAssets: makeMediaAssets(3))
        vm.selectionMode = true
        vm.selectedIndices = [0, 1, 2]
        vm.cancelSelection()
        XCTAssertFalse(vm.selectionMode)
        XCTAssertTrue(vm.selectedIndices.isEmpty)
    }

    func test_cancelSelection_idempotent() {
        let vm = makeVM(mediaAssets: makeMediaAssets(3))
        vm.cancelSelection()
        vm.cancelSelection()
        XCTAssertFalse(vm.selectionMode)
        XCTAssertTrue(vm.selectedIndices.isEmpty)
    }

    // MARK: - handleDelete

    func test_handleDelete_removesSelectedAssets() {
        let items = makeMediaAssets(3)
        let keepID = items[1].id
        let vm = makeVM(mediaAssets: items)
        vm.selectedIndices = [0, 2]
        vm.handleDelete()
        XCTAssertEqual(vm.mediaAssets.count, 1)
        XCTAssertEqual(vm.mediaAssets.first?.id, keepID)
    }

    func test_handleDelete_clearsSelectionAndMode() {
        let vm = makeVM(mediaAssets: makeMediaAssets(3))
        vm.selectionMode = true
        vm.selectedIndices = [0]
        vm.handleDelete()
        XCTAssertTrue(vm.selectedIndices.isEmpty)
        XCTAssertFalse(vm.selectionMode)
    }

    func test_handleDelete_outOfBoundsIndex_ignored() {
        let vm = makeVM(mediaAssets: makeMediaAssets(2))
        vm.selectedIndices = [5]
        vm.handleDelete()
        XCTAssertEqual(vm.mediaAssets.count, 2, "Out-of-bounds selection must not delete anything")
    }

    func test_handleDelete_allAssets_leavesEmpty() {
        let vm = makeVM(mediaAssets: makeMediaAssets(2))
        vm.selectedIndices = [0, 1]
        vm.handleDelete()
        XCTAssertTrue(vm.mediaAssets.isEmpty)
    }

    func test_handleDelete_clampsCurrentIndex() {
        let vm = makeVM(mediaAssets: makeMediaAssets(3), initialIndex: 2)
        vm.selectedIndices = [1, 2]
        vm.handleDelete()
        XCTAssertEqual(vm.mediaAssets.count, 1)
        XCTAssertEqual(vm.currentIndex, 0, "currentIndex must clamp after deletion")
    }

    func test_handleDelete_largeSelection_correctCountRemains() {
        let vm = makeVM(mediaAssets: makeMediaAssets(10))
        vm.selectedIndices = [0, 2, 4, 6, 8]
        vm.handleDelete()
        XCTAssertEqual(vm.mediaAssets.count, 5)
    }

    func test_handleDelete_videoItems_removed() {
        let items: [MediaAsset] = [
            .photo(PhotoAsset(image: UIImage(systemName: "star")!)),
            .video(URL(string: "https://example.com/v.mp4")!)
        ]
        let vm = makeVM(mediaAssets: items)
        vm.selectedIndices = [1]
        vm.handleDelete()
        XCTAssertEqual(vm.mediaAssets.count, 1)
        XCTAssertNotNil(vm.mediaAssets.first?.photoAsset, "Only the photo should remain")
    }

    // MARK: - Selection mode / content visibility

    func test_selectionMode_defaultIsFalse() {
        let vm = makeVM(mediaAssets: makeMediaAssets(3))
        XCTAssertFalse(vm.selectionMode)
    }

    func test_selectionMode_setTrue_gridShown() {
        let vm = makeVM(mediaAssets: makeMediaAssets(3))
        vm.selectionMode = true
        XCTAssertTrue(vm.selectionMode)
    }

    func test_selectionMode_cancelSelection_contentViewRestored() {
        let vm = makeVM(mediaAssets: makeMediaAssets(3))
        vm.selectionMode = true
        vm.cancelSelection()
        XCTAssertFalse(vm.selectionMode)
    }

    func test_selectionMode_handleDelete_contentViewRestored() {
        let vm = makeVM(mediaAssets: makeMediaAssets(3))
        vm.selectionMode = true
        vm.selectedIndices = [0]
        vm.handleDelete()
        XCTAssertFalse(vm.selectionMode)
    }

    // MARK: - handleSave

    func test_handleSave_callsDelegate() {
        let delegate = MockDelegate()
        let config = HImageViewerConfiguration(delegate: delegate)
        let vm = makeVM(mediaAssets: makeMediaAssets(2), config: config)
        vm.comment = "Nice photo"
        vm.handleSave()
        XCTAssertTrue(delegate.didTapSaveCalled)
        XCTAssertEqual(delegate.lastSaveComment, "Nice photo")
        XCTAssertEqual(delegate.lastSavePhotos?.count, 2)
    }

    func test_handleSave_onlyPassesPhotos_notVideos() {
        let delegate = MockDelegate()
        let config = HImageViewerConfiguration(delegate: delegate)
        let items: [MediaAsset] = [
            .photo(PhotoAsset(image: UIImage(systemName: "star")!)),
            .video(URL(string: "https://example.com/v.mp4")!)
        ]
        let vm = makeVM(mediaAssets: items, config: config)
        vm.handleSave()
        XCTAssertTrue(delegate.didTapSaveCalled)
        XCTAssertEqual(delegate.lastSavePhotos?.count, 1,
                       "Videos must be excluded from the photos passed to the delegate")
    }

    func test_handleSave_noDelegate_doesNotCrash() {
        let vm = makeVM(mediaAssets: makeMediaAssets(1))
        XCTAssertNoThrow(vm.handleSave())
    }

    // MARK: - didDeleteMediaAssets callback

    func test_handleDelete_callsDidDeleteDelegate() {
        let delegate = MockDelegate()
        let config = HImageViewerConfiguration(delegate: delegate)
        let items = makeMediaAssets(3)
        let vm = makeVM(mediaAssets: items, config: config)
        vm.selectedIndices = [0, 2]
        vm.handleDelete()
        XCTAssertTrue(delegate.didDeleteCalled)
        XCTAssertEqual(delegate.lastDeletedAssets?.count, 2)
    }

    func test_handleDelete_delegateReceivesCorrectIDs() {
        let delegate = MockDelegate()
        let config = HImageViewerConfiguration(delegate: delegate)
        let items = makeMediaAssets(3)
        let deletedIDs = Set([items[0].id, items[2].id])
        let vm = makeVM(mediaAssets: items, config: config)
        vm.selectedIndices = [0, 2]
        vm.handleDelete()
        let receivedIDs = Set(delegate.lastDeletedAssets?.map(\.id) ?? [])
        XCTAssertEqual(receivedIDs, deletedIDs)
    }

    func test_handleDelete_emptySelection_doesNotCallDelegate() {
        let delegate = MockDelegate()
        let config = HImageViewerConfiguration(delegate: delegate)
        let vm = makeVM(mediaAssets: makeMediaAssets(3), config: config)
        vm.handleDelete()
        XCTAssertFalse(delegate.didDeleteCalled)
    }

    func test_handleDelete_noDelegate_doesNotCrash() {
        let vm = makeVM(mediaAssets: makeMediaAssets(3))
        vm.selectedIndices = [0]
        XCTAssertNoThrow(vm.handleDelete())
    }

    // MARK: - didChangePage callback

    func test_currentIndex_change_callsDidChangePageDelegate() {
        let delegate = MockDelegate()
        let config = HImageViewerConfiguration(delegate: delegate)
        let vm = makeVM(mediaAssets: makeMediaAssets(3), config: config)
        vm.currentIndex = 1
        XCTAssertTrue(delegate.didChangePageCalled)
        XCTAssertEqual(delegate.lastPageIndex, 1)
    }

    func test_currentIndex_sameValue_doesNotCallDelegate() {
        let delegate = MockDelegate()
        let config = HImageViewerConfiguration(delegate: delegate)
        let vm = makeVM(mediaAssets: makeMediaAssets(3), config: config)
        vm.currentIndex = 0   // already 0 — no change
        XCTAssertFalse(delegate.didChangePageCalled)
    }

    func test_currentIndex_multipleChanges_callCountMatches() {
        let delegate = MockDelegate()
        let config = HImageViewerConfiguration(delegate: delegate)
        let vm = makeVM(mediaAssets: makeMediaAssets(5), config: config)
        vm.currentIndex = 1
        vm.currentIndex = 2
        vm.currentIndex = 3
        XCTAssertEqual(delegate.pageChangeCallCount, 3)
    }

    func test_currentIndex_noDelegate_doesNotCrash() {
        let vm = makeVM(mediaAssets: makeMediaAssets(3))
        XCTAssertNoThrow(vm.currentIndex = 2)
    }
}
