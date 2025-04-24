//
//  ImageViewer.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 21/04/2025.
//

import SwiftUI
import Photos
import AVFoundation

public struct HImageViewer: View {
    
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
            
            TopBar
                .padding(.horizontal)
                .padding(.top, 12)
            
            if isSinglePhotoMode {
                if let videoURL = selectedVideo {
                    VideoPlayerView(videoURL: videoURL)
                        .cornerRadius(10)
                        .padding()
                } else if let firstAsset = assets.first {
                    PhotoView(photo: firstAsset, isSinglePhotoMode: true)
                        .cornerRadius(10)
                        .padding()
                }
            } else {
                MultiPhotoGrid (
                    assets: assets,
                    selectedIndices: selectedIndices,
                    selectionMode: selectionMode,
                    onSelectToggle: handleSelection
                )
            }

            Spacer()
            BottomBar
                
        }
//        .onDisappear {
//            delegate?.didAddPhotos(assets)
//        }
    }
    
    // MARK: - Top Bar
    private var TopBar: some View {
        HStack {
            if !selectionMode {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .padding(3)
                        .foregroundStyle(.gray)
                }
                .buttonStyle(.bordered)
                .clipShape(Circle())
            }
            Spacer()

            HStack(spacing: 8) {
                if !isSinglePhotoMode {
                    Button(selectionMode ? "Done" : "Select") {
                        selectionMode = !selectionMode
                    }
                    .buttonStyle(.borderless)
                } else {
//                    if showEditOptions {
//                        Button(action: {}) {
//                            Image(systemName: "crop")
//                                .font(.subheadline)
//                        }
//                        Button(action: {}) {
//                            Image(systemName: "pencil.tip")
//                                .font(.subheadline)
//                        }
//                    }

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
                }
            }
        }
    }
    
    // MARK: - Bottom Bar
    private var BottomBar: some View {
        VStack {
            Spacer()
            HStack {
                if isSinglePhotoMode {
                    commentSection
                } else {
                    Spacer()
                }

                Button(action: {
                    if selectionMode {
                        handleDelete()
                    } else {
                        handleSave()
                    }
                }) {
                    Text(selectionMode ? "Remove" : "Save")
                        .bold()
                }
                .buttonStyle(.borderedProminent)
                .tint(.gray)
                .padding(.trailing)
                .padding(.bottom, 16)
            }
        }
    }
    
    // MARK: - Comment Section (single photo only)
    private var commentSection: some View {
            TextField("Add a comment ...", text: $comment)
                .textFieldStyle(.roundedBorder)
                .padding([.horizontal, .bottom])
                .frame(minHeight: 50)
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
        let deletedAssets = selectedIndices.map { assets[$0] }
        assets.removeAll { asset in
            deletedAssets.contains(where: { $0.id == asset.id })
        }
        selectedIndices.removeAll()
//        delegate?.didDeletePhotos(deletedAssets)
        selectionMode = false
    }

    // MARK: - Save Handling

    private func handleSave() {
        delegate?.didSaveComment(comment)
    }

    // MARK: - Add More Placeholder (UIKit Picker)
//
//    private func handleAddMore() {
//        // UIKit picker trigger should be implemented via delegate or wrapper
//    }
}
 
#Preview {
    @State  var photoAssets: [PhotoAsset] = [PhotoAsset(image: UIImage(systemName: "person")!)]
    @State  var selectedVideo: URL? = nil
    
    HImageViewer(
        assets: $photoAssets,
        selectedVideo: $selectedVideo,
        delegate: nil
    )
}

//#Preview {
//    @State  var photoAssets: [PhotoAsset] = [PhotoAsset(image: UIImage(systemName: "person")!), PhotoAsset(image: UIImage(systemName: "person")!), PhotoAsset(image: UIImage(systemName: "person")!)]
//    @State  var selectedVideo: URL? = nil
//    
//    HImageViewer(
//        assets: $photoAssets,
//        selectedVideo: $selectedVideo,
//        delegate: nil
//    )
//}

