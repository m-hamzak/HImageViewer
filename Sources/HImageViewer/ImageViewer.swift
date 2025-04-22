//
//  ImageViewer.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 21/04/2025.
//

import SwiftUI
import Photos
import AVFoundation

public protocol ImageViewerDelegate: AnyObject {
    func didAddPhotos(_ photos: [PhotoAsset])
    func didSaveComment(_ comment: String)
    func didDeletePhotos(_ photos: [PhotoAsset])
}

import SwiftUI
import Photos

public struct ImageViewer: View {
    @Binding private var assets: [PhotoAsset]
    @Binding private var selectedVideo: URL?
    private let isSinglePhotoMode: Bool
    private weak var delegate: ImageViewerDelegate?

    @State private var selectionMode: Bool = false
    @State private var selectedIndices: Set<Int> = []
    @State private var comment: String = ""

    @State private var showEditOptions: Bool = false
    @State private var selectedImages: Set<Int> = []
    @Environment(\.dismiss) private var dismiss
    
    public init(
        assets: Binding<[PhotoAsset]>,
        selectedVideo: Binding<URL?>,
        delegate: ImageViewerDelegate? = nil
    ) {
        self._assets = assets
        self._selectedVideo = selectedVideo
        self.isSinglePhotoMode = assets.wrappedValue.count == 1
        self.delegate = delegate
    }

    public var body: some View {
        VStack {
            
            topBar
                .padding(.horizontal)
                .padding(.top, 12)
            
            if isSinglePhotoMode {
                if let videoURL = selectedVideo {
                    VideoPlayerView(videoURL: videoURL)
                        .cornerRadius(10)
                        .padding()
                } else if let firstAsset = assets.first {
                    ThumbnailImageView(photo: firstAsset)
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
//            HStack {
//                Button(selectionMode ? "Delete" : "Select") {
//                    if selectionMode {
//                        handleDelete()
//                    } else {
//                        selectionMode = true
//                    }
//                }
//                .buttonStyle(.bordered)
//
//                Spacer()
//
//                Button("Save") {
//                    handleSaveComment()
//                }
//                .buttonStyle(.borderedProminent)
//            }
//            .padding()
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
//                        savedComment = comment
                    }) {
                        Text("Save")
                            .bold()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.gray)
                    .padding(.trailing)
                    .padding(.bottom, 16)
                }
            }
        }
        .onDisappear {
            delegate?.didAddPhotos(assets)
        }
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.headline)
                    .padding(3)
                    .foregroundStyle(.gray)
            }
            .buttonStyle(.bordered)
            .clipShape(Circle())

            Spacer()

            HStack(spacing: 8) {
//                if isMultiPhotoMode {
//                    Button(action: {
//                        withAnimation {
//                            showEditOptions.toggle()
//                            if !showEditOptions {
//                                selectedImages.removeAll()
//                            }
//                        }
//                    }) {
//                        Text("Select")
//                            .bold()
//                    }
//                    .buttonStyle(.bordered)
//                    .tint(.gray)
//                } else {
                    if showEditOptions {
                        Button(action: {}) {
                            Image(systemName: "crop")
                                .font(.subheadline)
                        }
                        Button(action: {}) {
                            Image(systemName: "pencil.tip")
                                .font(.subheadline)
                        }
                    }

                    Button(action: {
                        withAnimation {
                            showEditOptions.toggle()
                        }
                    }) {
                        Image(systemName: "pencil")
                            .font(.headline)
                            .padding(3)
                            .foregroundStyle(.gray)
                    }
                    .buttonStyle(.bordered)
                    .clipShape(Circle())
//                }
            }
        }
    }

    // MARK: - Selection Handling

    private func handleSelection(_ index: Int) {
        if selectedIndices.contains(index) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.insert(index)
        }
    }

    // MARK: - Delete Handling

    private func handleDelete() {
//        let deletedAssets = selectedIndices.map { assets[$0] }
//        assets.removeAll { asset in
//            deletedAssets.contains(where: { $0.id == asset.id })
//        }
//        selectedIndices.removeAll()
//        delegate?.didDeletePhotos(deletedAssets)
//        selectionMode = false
    }

    // MARK: - Save Handling

    private func handleSaveComment() {
//        delegate?.didSaveComment(comment)
    }

    // MARK: - Add More Placeholder (UIKit Picker)

    private func handleAddMore() {
        // UIKit picker trigger should be implemented via delegate or wrapper
    }
}


