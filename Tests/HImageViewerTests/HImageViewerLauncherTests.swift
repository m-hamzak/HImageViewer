//
//  HImageViewerLauncherTests.swift
//  HImageViewerTests
//
//  Created by Hamza Khalid on 21/04/2026.
//
//  Verifies HImageViewerLauncher's present and push entry points.
//  Tests run on the main actor so UIKit calls are safe.
//

import XCTest
import SwiftUI
import UIKit
@testable import HImageViewer

@MainActor
final class HImageViewerLauncherTests: XCTestCase {

    // MARK: - Helpers

    private func makeMediaAssets(_ count: Int = 1) -> [MediaAsset] {
        (0..<count).map { _ in .photo(PhotoAsset(image: UIImage(systemName: "star")!)) }
    }

    /// Returns a `UIViewController` embedded in a `UINavigationController`
    /// and installed in the key window so UIKit presentation works.
    private func makeNavigationStack() -> (nav: UINavigationController, root: UIViewController) {
        let root = UIViewController()
        let nav  = UINavigationController(rootViewController: root)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = nav
        window.makeKeyAndVisible()
        return (nav, root)
    }

    /// Returns a standalone `UIViewController` with no navigation controller.
    private func makeStandaloneVC() -> UIViewController {
        let vc = UIViewController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = vc
        window.makeKeyAndVisible()
        return vc
    }

    // MARK: - present

    func test_present_presentsHostingController() {
        let vc = makeStandaloneVC()
        HImageViewerLauncher.present(from: vc, mediaAssets: makeMediaAssets())
        XCTAssertNotNil(vc.presentedViewController,
                        "present must push a hosting controller modally")
    }

    func test_present_presentedVCIsHostingController() {
        let vc = makeStandaloneVC()
        HImageViewerLauncher.present(from: vc, mediaAssets: makeMediaAssets())
        XCTAssertTrue(vc.presentedViewController is UIHostingController<MediaViewerContainer>,
                      "Presented controller must be a UIHostingController wrapping MediaViewerContainer")
    }

    func test_present_usesFullScreenStyle() {
        let vc = makeStandaloneVC()
        HImageViewerLauncher.present(from: vc, mediaAssets: makeMediaAssets())
        XCTAssertEqual(vc.presentedViewController?.modalPresentationStyle, .fullScreen)
    }

    func test_present_multipleAssets_presentsHostingController() {
        let vc = makeStandaloneVC()
        HImageViewerLauncher.present(from: vc, mediaAssets: makeMediaAssets(3))
        XCTAssertNotNil(vc.presentedViewController)
    }

    // MARK: - push

    func test_push_pushesOntoNavigationStack() {
        let (nav, root) = makeNavigationStack()
        HImageViewerLauncher.push(from: root, mediaAssets: makeMediaAssets())
        XCTAssertEqual(nav.viewControllers.count, 2,
                       "push must add the viewer to the navigation stack")
    }

    func test_push_pushedVCIsHostingController() {
        let (nav, root) = makeNavigationStack()
        HImageViewerLauncher.push(from: root, mediaAssets: makeMediaAssets())
        XCTAssertTrue(nav.viewControllers.last is UIHostingController<MediaViewerContainer>,
                      "Pushed controller must be a UIHostingController wrapping MediaViewerContainer")
    }

    func test_push_noNavigationController_isNoOp() {
        let vc = makeStandaloneVC()
        HImageViewerLauncher.push(from: vc, mediaAssets: makeMediaAssets())
        XCTAssertNil(vc.presentedViewController,
                     "push without a navigation controller must be a silent no-op")
    }

    func test_push_multipleAssets_pushesOntoStack() {
        let (nav, root) = makeNavigationStack()
        HImageViewerLauncher.push(from: root, mediaAssets: makeMediaAssets(5))
        XCTAssertEqual(nav.viewControllers.count, 2)
    }

    // MARK: - present vs push

    func test_present_isModal_push_isNavigation() {
        let (nav, root) = makeNavigationStack()

        // Present from a different VC so the stack isn't modified.
        let standalone = makeStandaloneVC()
        HImageViewerLauncher.present(from: standalone, mediaAssets: makeMediaAssets())
        XCTAssertNotNil(standalone.presentedViewController, "present → modal")

        // Push from the nav-stack VC.
        HImageViewerLauncher.push(from: root, mediaAssets: makeMediaAssets())
        XCTAssertEqual(nav.viewControllers.count, 2, "push → navigation stack")
    }
}
