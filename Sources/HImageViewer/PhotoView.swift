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
    @State private var imageLoadTask: Task<Void, Never>?
    @ObservedObject var photo: PhotoAsset
    let isSinglePhotoMode: Bool

    // MARK: - Body

    public var body: some View {
        VStack {
            if isSinglePhotoMode {
                Spacer()
            }
            if let image = photo.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: isSinglePhotoMode ? .fit : .fill)
                    .cornerRadius(12) 
            } else if didFailToLoad {
                Color.red.opacity(0.2)
                    .overlay(
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                            .font(.largeTitle)
                    )
            } else {
                Color.gray.opacity(0.1)
                    .overlay(
                        ProgressView()
                    )
            }
            if isSinglePhotoMode {
                Spacer()
            }
        }
        .onAppear {
            guard photo.image == nil && !didFailToLoad else { return }

            if let url = photo.imageURL {
                // Load image from remote URL using async/await
                imageLoadTask = Task {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        guard !Task.isCancelled else { return }

                        if let loadedImage = UIImage(data: data) {
                            await MainActor.run {
                                self.photo.image = loadedImage
                            }
                        } else {
                            await MainActor.run {
                                self.didFailToLoad = true
                            }
                        }
                    } catch {
                        guard !Task.isCancelled else { return }
                        await MainActor.run {
                            self.didFailToLoad = true
                        }
                    }
                }
                return
            }

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
            imageLoadTask?.cancel()
        }
    }
}
