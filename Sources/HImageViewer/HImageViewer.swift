//
//  HImageViewer.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 21/04/2025.
//

import SwiftUI
import Photos
import AVFoundation

/// A SwiftUI view for displaying and managing photos and videos with editing capabilities.
///
/// `HImageViewer` provides a full-screen viewer for displaying single or multiple photos/videos with support for:
/// - Single photo viewing with optional editing
/// - Multi-photo grid with selection and deletion
/// - Video playback
/// - Optional comment/title display
/// - Upload progress tracking
///
/// ## Usage
///
/// ### Basic single photo viewer:
/// ```swift
/// @State var assets = [PhotoAsset(image: myImage)]
/// @State var selectedVideo: URL? = nil
///
/// HImageViewer(
///     assets: $assets,
///     selectedVideo: $selectedVideo
/// )
/// ```
///
/// ### Multi-photo viewer with configuration:
/// ```swift
/// @State var assets = PhotoAsset.from(uiImages: myImages)
/// @State var selectedVideo: URL? = nil
///
/// HImageViewer(
///     assets: $assets,
///     selectedVideo: $selectedVideo,
///     configuration: .init(
///         showSaveButton: true,
///         showEditButton: true,
///         delegate: self
///     )
/// )
/// ```
///
/// - Important: The viewer automatically dismisses when all assets are deleted in multi-photo mode.
/// - Note: For upload progress tracking, pass a shared `HImageViewerUploadState` via configuration.
public struct HImageViewer: View {

    // MARK: - Properties

    @Binding private var assets: [PhotoAsset]
    @Binding private var selectedVideo: URL?

    @State private var selectionMode: Bool = false
    @State private var selectedIndices: Set<Int> = []
    @State private var comment: String
    @State private var wasImageEdited = false

    @Environment(\.dismiss) private var dismiss
    @ObservedObject var uploadState: HImageViewerUploadState
    
    private let config: HImageViewerConfiguration
    private weak var delegate: HImageViewerControlDelegate?

    // MARK: - Computed Properties

    private var isSinglePhotoMode: Bool {
        assets.count <= 1
    }
    private var isUploading: Bool {
        (uploadState.progress ?? 0) > 0 && (uploadState.progress ?? 0) < 1.0
    }
    private var shouldShowSaveButton: Bool {
        if isSinglePhotoMode {
            return wasImageEdited || config.showSaveButton
        } else {
            return config.showSaveButton
        }
    }

    // MARK: - Initialization

    /// Creates a new image viewer instance.
    ///
    /// - Parameters:
    ///   - assets: A binding to an array of `PhotoAsset` objects to display. The array is modified when photos are deleted.
    ///   - selectedVideo: A binding to an optional video URL. If provided, displays video player instead of photo.
    ///   - configuration: Configuration object specifying viewer behavior. Defaults to standard configuration.
    ///
    /// - Note: Pass an empty array for `assets` if only displaying video via `selectedVideo`.
    public init(
        assets: Binding<[PhotoAsset]>,
        selectedVideo: Binding<URL?>,
        configuration: HImageViewerConfiguration = .init()
    ) {
        self._assets = assets
        self._selectedVideo = selectedVideo
        self.config = configuration
        self._comment = State(initialValue: config.initialComment ?? "")
        self.delegate = configuration.delegate
        if let provided = config.uploadState {
                uploadState = provided
            } else {
                uploadState = HImageViewerUploadState()
            }
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            mainComponent
            .onAppear {
                        if uploadState.progress == 1.0 {
                            uploadState.progress = nil
                        }
                    }
            .disabled(uploadState.progress ?? 0 > 0)
            
                if let progress = uploadState.progress {
                VStack {
                    Spacer()
                        ProgressRingOverlayView(progress: progress, title: "Uploading")
                            .padding()
                            .opacity(progress < 1.0 ? 1 : 0)
                                    .animation(.easeOut(duration: 0.3), value: progress)
                                    .onChange(of: progress) { newProgress in
                                                guard newProgress >= 1 else { return }
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                        dismiss()
                                                    }
                                            }
                    
                    Spacer()
                }
                .transition(.opacity)
            }
        }
    }

    // MARK: - Subviews

    private var mainComponent: some View {
        VStack {

            TopBar(config: TopBarConfig (
                isSinglePhotoMode: isSinglePhotoMode,
                showEditButton: config.showEditButton,
                selectionMode: selectionMode,
                onDismiss: { dismiss(); delegate?.didTapCloseButton() },
                onSelectToggle: { selectionMode.toggle() },
                onEdit: {
                    guard let firstAsset = assets.first else { return }
                    delegate?.didTapEditButton(photo: firstAsset)
                }
            ))
            
            if isSinglePhotoMode {
                if let videoURL = selectedVideo {
                    VideoPlayerView(videoURL: videoURL)
                        .padding()
                } else if let firstAsset = assets.first {
                    PhotoView(photo: firstAsset, isSinglePhotoMode: true)
                        .padding()
                }
            } else {
                MultiPhotoGrid (
                    assets: assets,
                    selectedIndices: selectedIndices,
                    selectionMode: selectionMode,
                    onSelectToggle: handleSelection
                )
                Spacer()
            }
            
            BottomBar(comment: $comment, config: BottomBarConfig(
                isSinglePhotoMode: isSinglePhotoMode,
                selectionMode: selectionMode,
                showSaveButton: shouldShowSaveButton,
                showCommentBox: config.showCommentBox,
                title: config.title,
                onSave: { handleSave() },
                onDelete: { handleDelete() }
            ))
            
        }
        .onChange(of: assets.first?.image as UIImage?) { _ in
           if isSinglePhotoMode {
                wasImageEdited = true
            }
        }
        .onChange(of: assets.count) { newCount in
            if newCount == 0 {
                dismiss()
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
        let deletedAssets = selectedIndices
            .filter { $0 < assets.count }
            .compactMap { assets[safe: $0] }
        assets.removeAll { asset in
            deletedAssets.contains(where: { $0.id == asset.id })
        }
        selectedIndices.removeAll()
        selectionMode = false
    }

    // MARK: - Save Handling

    private func handleSave() {
        delegate?.didTapSaveButton(comment: comment, photos: assets)
    }
}

// MARK: - Array Extension

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Previews

#Preview {
    @State  var photoAssets: [PhotoAsset] = [PhotoAsset(image: UIImage(systemName: "person")!)]
    @State  var selectedVideo: URL? = nil
    
    HImageViewer(
        assets: $photoAssets,
        selectedVideo: $selectedVideo
    )
}

#Preview {
    @State  var photoAssets: [PhotoAsset] = [PhotoAsset(image: UIImage(systemName: "person")!), PhotoAsset(image: UIImage(systemName: "person")!), PhotoAsset(image: UIImage(systemName: "person")!), PhotoAsset(image: UIImage(systemName: "person")!), PhotoAsset(image: UIImage(systemName: "person")!)]
    @State  var selectedVideo: URL? = nil

    HImageViewer(
        assets: $photoAssets,
        selectedVideo: $selectedVideo
    )
}

