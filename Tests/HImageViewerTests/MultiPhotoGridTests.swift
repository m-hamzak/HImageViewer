//
//  MultiPhotoGridTests.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 27/04/2026.
//

import XCTest
@testable import HImageViewer

@MainActor
final class MultiPhotoGridTests: XCTestCase {

    // MARK: - tileLabel(for:at:)

    func test_tileLabel_photo_atIndexZero() {
        let asset = MediaAsset.photo(PhotoAsset(image: UIImage(systemName: "photo")!))
        XCTAssertEqual(MultiPhotoGrid.tileLabel(for: asset, at: 0), "Photo 1")
    }

    func test_tileLabel_photo_atIndexOne() {
        let asset = MediaAsset.photo(PhotoAsset(image: UIImage(systemName: "photo")!))
        XCTAssertEqual(MultiPhotoGrid.tileLabel(for: asset, at: 1), "Photo 2")
    }

    func test_tileLabel_photo_atLargeIndex() {
        let asset = MediaAsset.photo(PhotoAsset(image: UIImage(systemName: "photo")!))
        XCTAssertEqual(MultiPhotoGrid.tileLabel(for: asset, at: 9), "Photo 10")
    }

    func test_tileLabel_video_atIndexZero() {
        let url = URL(string: "https://example.com/video.mp4")!
        let asset = MediaAsset.video(url)
        XCTAssertEqual(MultiPhotoGrid.tileLabel(for: asset, at: 0), "Video 1")
    }

    func test_tileLabel_video_atIndexTwo() {
        let url = URL(string: "https://example.com/video.mp4")!
        let asset = MediaAsset.video(url)
        XCTAssertEqual(MultiPhotoGrid.tileLabel(for: asset, at: 2), "Video 3")
    }

    func test_tileLabel_photo_labelContainsHumanReadableNumber() {
        // 0-based index 4 → human-readable "5"
        let asset = MediaAsset.photo(PhotoAsset(image: UIImage(systemName: "star")!))
        let label = MultiPhotoGrid.tileLabel(for: asset, at: 4)
        XCTAssertTrue(label.contains("5"), "Label must display index + 1 (1-based)")
        XCTAssertFalse(label.contains("4"), "Label must not contain the raw 0-based index")
    }

    func test_tileLabel_video_labelContainsHumanReadableNumber() {
        let url = URL(string: "https://example.com/clip.mp4")!
        let asset = MediaAsset.video(url)
        let label = MultiPhotoGrid.tileLabel(for: asset, at: 0)
        XCTAssertTrue(label.contains("1"), "First video label must contain '1'")
    }

    func test_tileLabel_photo_prefixIsPhoto() {
        let asset = MediaAsset.photo(PhotoAsset(image: UIImage(systemName: "photo")!))
        XCTAssertTrue(
            MultiPhotoGrid.tileLabel(for: asset, at: 0).hasPrefix("Photo"),
            "Photo tile label must start with 'Photo'"
        )
    }

    func test_tileLabel_video_prefixIsVideo() {
        let url = URL(string: "https://example.com/video.mp4")!
        let asset = MediaAsset.video(url)
        XCTAssertTrue(
            MultiPhotoGrid.tileLabel(for: asset, at: 0).hasPrefix("Video"),
            "Video tile label must start with 'Video'"
        )
    }
}
