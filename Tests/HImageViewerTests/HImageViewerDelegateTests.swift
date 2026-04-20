//
//  HImageViewerDelegateTests.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 22/02/2026.
//

import XCTest
@testable import HImageViewer

@MainActor
final class HImageViewerDelegateTests: XCTestCase {

    // MARK: - Default Implementation Tests

    func test_defaultImpl_didTapSaveButton_doesNotCrash() {
        let delegate = MinimalDelegate()
        // This should NOT crash — the default implementation is an empty function
        delegate.didTapSaveButton(comment: "test", photos: [])
        // Reaching this line = test passed (no crash occurred)
    }

    func test_defaultImpl_didTapCloseButton_doesNotCrash() {
        let delegate = MinimalDelegate()
        delegate.didTapCloseButton()
    }

    func test_defaultImpl_didTapEditButton_doesNotCrash() {
        let delegate = MinimalDelegate()
        let photo = PhotoAsset(image: UIImage(systemName: "star")!)
        delegate.didTapEditButton(photo: photo)
    }

    // MARK: - Custom Implementation Tests

    func test_customImpl_didTapSaveButton_isCalled() {
        let delegate = MockDelegate()
        let photo = PhotoAsset(image: UIImage(systemName: "star")!)

        // Simulate the viewer calling the delegate
        delegate.didTapSaveButton(comment: "Nice photo", photos: [photo])

        // Verify the mock recorded everything correctly
        XCTAssertTrue(delegate.didTapSaveCalled, "didTapSaveButton should have been called")
        XCTAssertEqual(delegate.lastSaveComment, "Nice photo", "Comment should be passed through")
        XCTAssertEqual(delegate.lastSavePhotos?.count, 1, "Photos array should contain 1 photo")
    }

    func test_customImpl_didTapCloseButton_isCalled() {
        let delegate = MockDelegate()
        delegate.didTapCloseButton()
        XCTAssertTrue(delegate.didTapCloseCalled, "didTapCloseButton should have been called")
    }

    func test_customImpl_didTapEditButton_isCalled() {
        let delegate = MockDelegate()
        let photo = PhotoAsset(image: UIImage(systemName: "star")!)

        delegate.didTapEditButton(photo: photo)

        XCTAssertTrue(delegate.didTapEditCalled, "didTapEditButton should have been called")
        XCTAssertNotNil(delegate.lastEditPhoto, "The photo should be passed to the delegate")
    }

    // MARK: - Selective Adoption Test

    func test_selectiveAdoption_allMethodsCallable() {
        let delegate = MinimalDelegate()

        // All three calls should succeed without crash
        delegate.didTapSaveButton(comment: "test", photos: [])
        delegate.didTapCloseButton()
        delegate.didTapEditButton(photo: PhotoAsset(image: UIImage(systemName: "star")!))

        // If we reach here, selective adoption works correctly
    }

    // MARK: - Multiple calls

    func test_saveCalledMultipleTimes_lastCommentWins() {
        let delegate = MockDelegate()
        let photo = PhotoAsset(image: UIImage(systemName: "star")!)
        delegate.didTapSaveButton(comment: "first",  photos: [photo])
        delegate.didTapSaveButton(comment: "second", photos: [])
        XCTAssertEqual(delegate.lastSaveComment, "second")
    }

    func test_saveCalledMultipleTimes_lastPhotosWin() {
        let delegate = MockDelegate()
        let p1 = PhotoAsset(image: UIImage(systemName: "star")!)
        let p2 = PhotoAsset(image: UIImage(systemName: "heart")!)
        delegate.didTapSaveButton(comment: "a", photos: [p1])
        delegate.didTapSaveButton(comment: "b", photos: [p1, p2])
        XCTAssertEqual(delegate.lastSavePhotos?.count, 2)
    }

    func test_closeCalledMultipleTimes_flagRemainsTrue() {
        let delegate = MockDelegate()
        delegate.didTapCloseButton()
        delegate.didTapCloseButton()
        XCTAssertTrue(delegate.didTapCloseCalled)
    }

    func test_reset_clearsAllFields() {
        let delegate = MockDelegate()
        let photo = PhotoAsset(image: UIImage(systemName: "star")!)
        delegate.didTapSaveButton(comment: "x", photos: [photo])
        delegate.didTapCloseButton()
        delegate.didTapEditButton(photo: photo)
        delegate.reset()

        XCTAssertFalse(delegate.didTapSaveCalled)
        XCTAssertFalse(delegate.didTapCloseCalled)
        XCTAssertFalse(delegate.didTapEditCalled)
        XCTAssertNil(delegate.lastSaveComment)
        XCTAssertNil(delegate.lastSavePhotos)
        XCTAssertNil(delegate.lastEditPhoto)
    }

    func test_saveWithEmptyPhotos_emptyArrayPropagated() {
        let delegate = MockDelegate()
        delegate.didTapSaveButton(comment: "", photos: [])
        XCTAssertEqual(delegate.lastSavePhotos?.count, 0)
    }

    func test_editPhoto_idMatchesPassedPhoto() {
        let delegate = MockDelegate()
        let photo = PhotoAsset(image: UIImage(systemName: "star")!)
        delegate.didTapEditButton(photo: photo)
        XCTAssertEqual(delegate.lastEditPhoto?.id, photo.id)
    }

    func test_saveNotCalledInitially() {
        let delegate = MockDelegate()
        XCTAssertFalse(delegate.didTapSaveCalled)
        XCTAssertNil(delegate.lastSaveComment)
    }

    func test_allThreeCallbacks_independentFlags() {
        let delegate = MockDelegate()
        let photo = PhotoAsset(image: UIImage(systemName: "star")!)

        delegate.didTapSaveButton(comment: "c", photos: [photo])
        XCTAssertTrue(delegate.didTapSaveCalled)
        XCTAssertFalse(delegate.didTapCloseCalled)
        XCTAssertFalse(delegate.didTapEditCalled)

        delegate.didTapCloseButton()
        XCTAssertTrue(delegate.didTapCloseCalled)
        XCTAssertFalse(delegate.didTapEditCalled)

        delegate.didTapEditButton(photo: photo)
        XCTAssertTrue(delegate.didTapEditCalled)
    }
}
