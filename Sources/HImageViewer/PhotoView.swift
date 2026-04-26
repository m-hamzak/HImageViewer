//
//  PhotoView.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 21/04/2025.
//

import SwiftUI
import Photos

public struct PhotoView: View {

    // MARK: - Properties

    @State private var didFailToLoad: Bool = false
    @ObservedObject var photo: PhotoAsset
    let isSinglePhotoMode: Bool

    // MARK: - Theming

    /// Accent color applied to the loading spinner. Defaults to `.blue`.
    var tintColor: Color = .blue
    /// Custom view shown while the photo loads. When `nil`, a gray background + spinner is shown.
    var placeholderView: AnyView? = nil
    /// Custom view shown when the photo fails to load. When `nil`, a red background + warning icon is shown.
    var errorView: AnyView? = nil
    /// Changes to this value animate the zoom back to its default state.
    /// Pass the viewer's `currentIndex` so zoom resets when the user navigates to a different page.
    var resetToken: Int = 0

    // MARK: - Body

    public var body: some View {
        VStack {
            if isSinglePhotoMode {
                Spacer()
            }
            if let image = photo.image {
                if isSinglePhotoMode {
                    ZoomableImageView(image: image, resetToken: resetToken)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .id(photo.id)
                        .accessibilityLabel("Photo")
                        .accessibilityAddTraits(.isImage)
                        .accessibilityHint("Double-tap to zoom")
                } else {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .accessibilityLabel("Photo")
                        .accessibilityAddTraits(.isImage)
                }
            } else if didFailToLoad {
                if let errorView {
                    errorView
                        .accessibilityLabel("Failed to load photo")
                } else {
                    defaultErrorView
                }
            } else {
                if let placeholderView {
                    placeholderView
                        .accessibilityLabel("Loading photo")
                } else {
                    defaultPlaceholderView
                }
            }
            if isSinglePhotoMode {
                Spacer()
            }
        }
        .onAppear {
            guard photo.image == nil, !didFailToLoad else { return }

            let completion: (UIImage?) -> Void = { img in
                if let img = img {
                    self.photo.image = img
                } else {
                    self.didFailToLoad = true
                }
            }

            if isSinglePhotoMode {
                photo.loadFullImage(completion: completion)
            } else {
                photo.loadThumbnail(targetSize: CGSize(width: 150, height: 150), completion: completion)
            }
        }
        .onDisappear {
            photo.cancelPendingLoad()
        }
    }

    // MARK: - Default state views

    private var defaultPlaceholderView: some View {
        Color.gray.opacity(0.1)
            .overlay(
                ProgressView()
                    .tint(tintColor)
            )
            .accessibilityLabel("Loading photo")
    }

    private var defaultErrorView: some View {
        Color.red.opacity(0.2)
            .overlay(
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.red)
                    .font(.largeTitle)
            )
            .accessibilityLabel("Failed to load photo")
    }
}
