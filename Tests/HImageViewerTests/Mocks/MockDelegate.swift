//
//  MockDelegate.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 22/02/2026.
//

import XCTest
@testable import HImageViewer

// MARK: - MockDelegate

/// Records every delegate call for test verification.
@MainActor
final class MockDelegate: @preconcurrency HImageViewerControlDelegate {

    // MARK: - Save Button Tracking

    var didTapSaveCalled = false
    var lastSaveComment: String?
    var lastSavePhotos: [PhotoAsset]?

    // MARK: - Close Button Tracking

    var didTapCloseCalled = false

    // MARK: - Edit Button Tracking

    var didTapEditCalled = false
    var lastEditPhoto: PhotoAsset?

    // MARK: - Delete Tracking

    var didDeleteCalled = false
    var lastDeletedAssets: [MediaAsset]?

    // MARK: - Page Change Tracking

    var didChangePageCalled = false
    var lastPageIndex: Int?
    var pageChangeCallCount: Int = 0

    // MARK: - Protocol Implementation

    func didTapSaveButton(comment: String, photos: [PhotoAsset]) {
        didTapSaveCalled = true
        lastSaveComment = comment
        lastSavePhotos = photos
    }

    func didTapCloseButton() {
        didTapCloseCalled = true
    }

    func didTapEditButton(photo: PhotoAsset) {
        didTapEditCalled = true
        lastEditPhoto = photo
    }

    func didDeleteMediaAssets(_ assets: [MediaAsset]) {
        didDeleteCalled = true
        lastDeletedAssets = assets
    }

    func didChangePage(to index: Int) {
        didChangePageCalled = true
        lastPageIndex = index
        pageChangeCallCount += 1
    }

    // MARK: - Helper Methods

    func reset() {
        didTapSaveCalled = false
        lastSaveComment = nil
        lastSavePhotos = nil
        didTapCloseCalled = false
        didTapEditCalled = false
        lastEditPhoto = nil
        didDeleteCalled = false
        lastDeletedAssets = nil
        didChangePageCalled = false
        lastPageIndex = nil
        pageChangeCallCount = 0
    }
}

// MARK: - MinimalDelegate

/// Uses only default protocol implementations — proves selective adoption works.
/// If this file compiles, it proves default implementations exist.
class MinimalDelegate: HImageViewerControlDelegate {}
