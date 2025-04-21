//
//  ImageViewer.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 21/04/2025.
//

import SwiftUI
import Photos
import AVFoundation

protocol ImageViewerDelegate: AnyObject {
    func didAddPhotos(_ photos: [PhotoAsset])
    func didSaveComment(_ comment: String)
    func didDeletePhotos(_ photos: [PhotoAsset])
}

struct ImageViewer: View {
    @Binding var assets: [PhotoAsset]
    @Binding var selectedVideo: URL?
    let isSinglePhotoMode: Bool
    weak var delegate: ImageViewerDelegate?

    @State private var selectionMode: Bool = false
    @State private var selectedIndices: Set<Int> = []
    @State private var comment: String = ""

    var body: some View {
        VStack {
            if isSinglePhotoMode {
                if let videoURL = selectedVideo {
                    VideoPlayerView(videoURL: videoURL)
                        .cornerRadius(10)
                        .padding()
                } else if let firstAsset = assets.first {
                    ThumbnailImageView(asset: firstAsset.asset)
                        .cornerRadius(10)
                        .padding()
                }
            } else {
                MultiPhotoGrid(
                    assets: assets,
                    selectedIndices: selectedIndices,
                    selectionMode: selectionMode,
                    onSelectToggle: handleSelection,
                    onAddMore: handleAddMore
                )
            }

            Spacer()

            // Bottom actions (Save, Select/Delete)
            HStack {
                Button(selectionMode ? "Delete" : "Select") {
                    if selectionMode {
                        handleDelete()
                    } else {
                        selectionMode = true
                    }
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Save") {
                    handleSaveComment()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .onDisappear {
            delegate?.didAddPhotos(assets)
        }
    }

    private func handleSelection(_ index: Int) {
        if selectedIndices.contains(index) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.insert(index)
        }
    }

    private func handleAddMore() {
        // Callback to UIKit for photo picker
    }

    private func handleDelete() {
        let deletedAssets = selectedIndices.map { assets[$0] }
        assets.removeAll { selectedIndices.contains(assets.firstIndex(of: $0)!) }
        selectedIndices.removeAll()
        delegate?.didDeletePhotos(deletedAssets)
        selectionMode = false
    }

    private func handleSaveComment() {
        delegate?.didSaveComment(comment)
    }
}
