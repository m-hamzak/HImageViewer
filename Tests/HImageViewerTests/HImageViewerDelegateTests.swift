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
        delegate.didTapSaveButton(comment: "test", photos: [])
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

    func test_defaultImpl_didDeleteMediaAssets_doesNotCrash() {
        let delegate = MinimalDelegate()
        delegate.didDeleteMediaAssets([])
    }

    func test_defaultImpl_didChangePage_doesNotCrash() {
        let delegate = MinimalDelegate()
        delegate.didChangePage(to: 3)
    }

    // MARK: - Custom Implementation Tests

    func test_customImpl_didTapSaveButton_isCalled() {
        let delegate = MockDelegate()
        let photo = PhotoAsset(image: UIImage(systemName: "star")!)
        delegate.didTapSaveButton(comment: "Nice photo", photos: [photo])
        XCTAssertTrue(delegate.didTapSaveCalled)
        XCTAssertEqual(delegate.lastSaveComment, "Nice photo")
        XCTAssertEqual(delegate.lastSavePhotos?.count, 1)
    }

    func test_customImpl_didTapCloseButton_isCalled() {
        let delegate = MockDelegate()
        delegate.didTapCloseButton()
        XCTAssertTrue(delegate.didTapCloseCalled)
    }

    func test_customImpl_didTapEditButton_isCalled() {
        let delegate = MockDelegate()
        let photo = PhotoAsset(image: UIImage(systemName: "star")!)
        delegate.didTapEditButton(photo: photo)
        XCTAssertTrue(delegate.didTapEditCalled)
        XCTAssertNotNil(delegate.lastEditPhoto)
    }

    func test_customImpl_didDeleteMediaAssets_isCalled() {
        let delegate = MockDelegate()
        let items: [MediaAsset] = [
            .photo(PhotoAsset(image: UIImage(systemName: "star")!))
        ]
        delegate.didDeleteMediaAssets(items)
        XCTAssertTrue(delegate.didDeleteCalled)
        XCTAssertEqual(delegate.lastDeletedAssets?.count, 1)
    }

    func test_customImpl_didChangePage_isCalled() {
        let delegate = MockDelegate()
        delegate.didChangePage(to: 2)
        XCTAssertTrue(delegate.didChangePageCalled)
        XCTAssertEqual(delegate.lastPageIndex, 2)
    }

    // MARK: - Selective Adoption Test

    func test_selectiveAdoption_allMethodsCallable() {
        let delegate = MinimalDelegate()
        delegate.didTapSaveButton(comment: "test", photos: [])
        delegate.didTapCloseButton()
        delegate.didTapEditButton(photo: PhotoAsset(image: UIImage(systemName: "star")!))
        delegate.didDeleteMediaAssets([])
        delegate.didChangePage(to: 0)
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

    func test_didChangePage_calledMultipleTimes_callCountAccumulates() {
        let delegate = MockDelegate()
        delegate.didChangePage(to: 0)
        delegate.didChangePage(to: 1)
        delegate.didChangePage(to: 2)
        XCTAssertEqual(delegate.pageChangeCallCount, 3)
        XCTAssertEqual(delegate.lastPageIndex, 2)
    }

    func test_reset_clearsAllFields() {
        let delegate = MockDelegate()
        let photo = PhotoAsset(image: UIImage(systemName: "star")!)
        delegate.didTapSaveButton(comment: "x", photos: [photo])
        delegate.didTapCloseButton()
        delegate.didTapEditButton(photo: photo)
        delegate.didDeleteMediaAssets([.photo(photo)])
        delegate.didChangePage(to: 3)
        delegate.reset()

        XCTAssertFalse(delegate.didTapSaveCalled)
        XCTAssertFalse(delegate.didTapCloseCalled)
        XCTAssertFalse(delegate.didTapEditCalled)
        XCTAssertFalse(delegate.didDeleteCalled)
        XCTAssertFalse(delegate.didChangePageCalled)
        XCTAssertNil(delegate.lastSaveComment)
        XCTAssertNil(delegate.lastSavePhotos)
        XCTAssertNil(delegate.lastEditPhoto)
        XCTAssertNil(delegate.lastDeletedAssets)
        XCTAssertNil(delegate.lastPageIndex)
        XCTAssertEqual(delegate.pageChangeCallCount, 0)
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

    func test_allCallbacks_independentFlags() {
        let delegate = MockDelegate()
        let photo = PhotoAsset(image: UIImage(systemName: "star")!)

        delegate.didTapSaveButton(comment: "c", photos: [photo])
        XCTAssertTrue(delegate.didTapSaveCalled)
        XCTAssertFalse(delegate.didTapCloseCalled)
        XCTAssertFalse(delegate.didTapEditCalled)
        XCTAssertFalse(delegate.didDeleteCalled)
        XCTAssertFalse(delegate.didChangePageCalled)

        delegate.didTapCloseButton()
        XCTAssertTrue(delegate.didTapCloseCalled)

        delegate.didTapEditButton(photo: photo)
        XCTAssertTrue(delegate.didTapEditCalled)

        delegate.didDeleteMediaAssets([.photo(photo)])
        XCTAssertTrue(delegate.didDeleteCalled)

        delegate.didChangePage(to: 1)
        XCTAssertTrue(delegate.didChangePageCalled)
    }

    // MARK: - didDeleteMediaAssets content

    func test_didDeleteMediaAssets_passesCorrectItems() {
        let delegate = MockDelegate()
        let photo = PhotoAsset(image: UIImage(systemName: "star")!)
        let videoURL = URL(string: "https://example.com/v.mp4")!
        let items: [MediaAsset] = [.photo(photo), .video(videoURL)]
        delegate.didDeleteMediaAssets(items)
        XCTAssertEqual(delegate.lastDeletedAssets?.count, 2)
    }

    func test_didDeleteMediaAssets_emptyArray_callsFlagTrue() {
        let delegate = MockDelegate()
        delegate.didDeleteMediaAssets([])
        XCTAssertTrue(delegate.didDeleteCalled)
        XCTAssertEqual(delegate.lastDeletedAssets?.count, 0)
    }
}
