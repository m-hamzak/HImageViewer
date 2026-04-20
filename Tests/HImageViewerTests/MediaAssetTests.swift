//
//  MediaAssetTests.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 20/04/2026.
//

import XCTest
@testable import HImageViewer

@MainActor
final class MediaAssetTests: XCTestCase {

    private let sampleImage = UIImage(systemName: "star")!
    private let sampleURL   = URL(string: "https://example.com/clip.mp4")!

    // MARK: - Photo kind

    func test_photo_kindIsPhoto() {
        let asset = MediaAsset.photo(PhotoAsset(image: sampleImage))
        if case .photo = asset.kind { /* pass */ } else {
            XCTFail("Expected .photo kind")
        }
    }

    func test_photo_photoAssetMatchesInput() {
        let photoAsset = PhotoAsset(image: sampleImage)
        let asset = MediaAsset.photo(photoAsset)
        XCTAssertEqual(asset.photoAsset, photoAsset, "photoAsset must match the wrapped value")
    }

    func test_photo_videoURLIsNil() {
        let asset = MediaAsset.photo(PhotoAsset(image: sampleImage))
        XCTAssertNil(asset.videoURL, "videoURL must be nil for a photo asset")
    }

    func test_photo_isPhotoTrueIsVideoFalse() {
        let asset = MediaAsset.photo(PhotoAsset(image: sampleImage))
        XCTAssertTrue(asset.isPhoto)
        XCTAssertFalse(asset.isVideo)
    }

    // MARK: - Video kind

    func test_video_kindIsVideo() {
        let asset = MediaAsset.video(sampleURL)
        if case .video = asset.kind { /* pass */ } else {
            XCTFail("Expected .video kind")
        }
    }

    func test_video_videoURLMatchesInput() {
        let asset = MediaAsset.video(sampleURL)
        XCTAssertEqual(asset.videoURL, sampleURL, "videoURL must match the wrapped value")
    }

    func test_video_photoAssetIsNil() {
        let asset = MediaAsset.video(sampleURL)
        XCTAssertNil(asset.photoAsset, "photoAsset must be nil for a video asset")
    }

    func test_video_isVideoTrueIsPhotoFalse() {
        let asset = MediaAsset.video(sampleURL)
        XCTAssertTrue(asset.isVideo)
        XCTAssertFalse(asset.isPhoto)
    }

    // MARK: - Identity

    func test_id_isStableAcrossAccesses() {
        let asset = MediaAsset.photo(PhotoAsset(image: sampleImage))
        XCTAssertEqual(asset.id, asset.id, "id must be the same on every access")
    }

    func test_equatable_sameInstance_isEqual() {
        let asset = MediaAsset.photo(PhotoAsset(image: sampleImage))
        XCTAssertEqual(asset, asset)
    }

    func test_equatable_differentInstances_areNotEqual() {
        let a = MediaAsset.photo(PhotoAsset(image: sampleImage))
        let b = MediaAsset.photo(PhotoAsset(image: sampleImage))
        XCTAssertNotEqual(a, b, "Two separately created assets must not be equal")
    }

    func test_equatable_sameIDExplicit_isEqual() {
        let sharedID = UUID()
        let a = MediaAsset(id: sharedID, kind: .video(sampleURL))
        let b = MediaAsset(id: sharedID, kind: .video(sampleURL))
        XCTAssertEqual(a, b, "Assets sharing the same explicit id must be equal")
    }

    // MARK: - Batch factory: from(uiImages:)

    func test_fromUIImages_returnsCorrectCount() {
        let images = [sampleImage, sampleImage, sampleImage]
        let assets = MediaAsset.from(uiImages: images)
        XCTAssertEqual(assets.count, 3)
    }

    func test_fromUIImages_allArePhotoKind() {
        let assets = MediaAsset.from(uiImages: [sampleImage, sampleImage])
        for asset in assets {
            XCTAssertTrue(asset.isPhoto, "from(uiImages:) must produce .photo assets")
        }
    }

    func test_fromUIImages_emptyInput_returnsEmpty() {
        XCTAssertTrue(MediaAsset.from(uiImages: []).isEmpty)
    }

    // MARK: - Batch factory: from(photoAssets:)

    func test_fromPhotoAssets_returnsCorrectCount() {
        let photos = [PhotoAsset(image: sampleImage), PhotoAsset(image: sampleImage)]
        let assets = MediaAsset.from(photoAssets: photos)
        XCTAssertEqual(assets.count, 2)
    }

    func test_fromPhotoAssets_allArePhotoKind() {
        let photos = [PhotoAsset(image: sampleImage)]
        let assets = MediaAsset.from(photoAssets: photos)
        XCTAssertTrue(assets[0].isPhoto)
    }

    // MARK: - Batch factory: from(videoURLs:)

    func test_fromVideoURLs_returnsCorrectCount() {
        let urls = [sampleURL, URL(string: "https://example.com/b.mp4")!]
        let assets = MediaAsset.from(videoURLs: urls)
        XCTAssertEqual(assets.count, 2)
    }

    func test_fromVideoURLs_allAreVideoKind() {
        let assets = MediaAsset.from(videoURLs: [sampleURL])
        XCTAssertTrue(assets[0].isVideo, "from(videoURLs:) must produce .video assets")
    }

    func test_fromVideoURLs_emptyInput_returnsEmpty() {
        XCTAssertTrue(MediaAsset.from(videoURLs: []).isEmpty)
    }

    // MARK: - Unique IDs

    func test_batchFactory_allAssetsHaveUniqueIDs() {
        let images = [sampleImage, sampleImage, sampleImage]
        let assets = MediaAsset.from(uiImages: images)
        let uniqueIDs = Set(assets.map(\.id))
        XCTAssertEqual(uniqueIDs.count, assets.count, "Each asset must have a unique id")
    }
}
