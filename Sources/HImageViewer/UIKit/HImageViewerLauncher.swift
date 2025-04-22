//
//  HImageViewerLauncher.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 22/04/2025.
//

import SwiftUI
import UIKit

public final class ImageViewerLauncher {
    @MainActor public static func present(
        from viewController: UIViewController,
        assets: [PhotoAsset],
        selectedVideo: URL? = nil,
        isSinglePhotoMode: Bool = false,
        delegate: ImageViewerDelegate? = nil
    ) {
        let viewer = ImageViewer(
            assets: .constant(assets),
            selectedVideo: .constant(selectedVideo),
            delegate: delegate
        )
        
        let hostingController = UIHostingController(rootView: viewer)
        hostingController.modalPresentationStyle = .fullScreen
        viewController.present(hostingController, animated: true)
    }
}
