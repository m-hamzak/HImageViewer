//
//  HImageViewer.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 21/04/2025.
//

import SwiftUI
import Photos

/// A SwiftUI view for displaying and managing photos and videos with editing capabilities.
///
/// `HImageViewer` provides a full-screen paged viewer with support for:
/// - Swipe paging through all items
/// - Pinch-to-zoom and double-tap zoom on photos
/// - Native AVKit controls for videos
/// - Multi-item selection and deletion via grid overlay
/// - Optional comment/title display
/// - Upload progress tracking
/// - Drag-to-dismiss
///
/// ## Photo-only usage (legacy)
///
/// ```swift
/// @State var assets = PhotoAsset.from(uiImages: myImages)
/// @State var selectedVideo: URL? = nil
///
/// HImageViewer(assets: $assets, selectedVideo: $selectedVideo)
/// ```
///
/// ## Mixed photo + video usage
///
/// ```swift
/// @State var items: [MediaAsset] = [
///     .photo(PhotoAsset(image: myImage)),
///     .video(videoURL)
/// ]
///
/// HImageViewer(mediaAssets: $items)
/// ```
///
/// - Important: The viewer automatically dismisses when all items are deleted.
public struct HImageViewer: View {

    // MARK: - Caller bindings (for syncing mutations back)

    @Binding private var externalAssets: [PhotoAsset]
    @Binding private var externalSelectedVideo: URL?
    @Binding private var externalMediaAssets: [MediaAsset]

    // MARK: - ViewModel

    @StateObject private var vm: HImageViewerViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialisation (mixed photo + video)

    /// Creates a new image/video viewer from a unified `MediaAsset` collection.
    ///
    /// Use this initialiser to display a mix of photos and videos in the same gallery.
    ///
    /// - Parameters:
    ///   - mediaAssets: A binding to the array of `MediaAsset` objects to display.
    ///     Modified when items are deleted.
    ///   - initialIndex: The index of the item to display first. Clamped to a valid range.
    ///     Defaults to `0`.
    ///   - configuration: Configuration object specifying viewer behaviour. Defaults to standard
    ///     configuration.
    public init(
        mediaAssets: Binding<[MediaAsset]>,
        initialIndex: Int = 0,
        configuration: HImageViewerConfiguration = .init()
    ) {
        self._externalMediaAssets = mediaAssets
        self._externalAssets = .constant([])
        self._externalSelectedVideo = .constant(nil)
        self._vm = StateObject(wrappedValue: HImageViewerViewModel(
            mediaAssets: mediaAssets.wrappedValue,
            usesMediaMode: true,
            initialIndex: initialIndex,
            config: configuration
        ))
    }

    // MARK: - Initialisation (photo-only, legacy)

    /// Creates a new image viewer instance.
    ///
    /// - Parameters:
    ///   - assets: A binding to the array of `PhotoAsset` objects to display. Modified when photos
    ///     are deleted.
    ///   - selectedVideo: A binding to an optional video URL. If non-nil, displays a video player
    ///     instead of the photo gallery.
    ///   - initialIndex: The index of the photo to display first. Clamped to a valid range.
    ///     Defaults to `0`.
    ///   - configuration: Configuration object specifying viewer behaviour. Defaults to standard
    ///     configuration.
    public init(
        assets: Binding<[PhotoAsset]>,
        selectedVideo: Binding<URL?>,
        initialIndex: Int = 0,
        configuration: HImageViewerConfiguration = .init()
    ) {
        self._externalAssets = assets
        self._externalSelectedVideo = selectedVideo
        self._externalMediaAssets = .constant([])
        self._vm = StateObject(wrappedValue: HImageViewerViewModel(
            assets: assets.wrappedValue,
            selectedVideo: selectedVideo.wrappedValue,
            usesMediaMode: false,
            initialIndex: initialIndex,
            config: configuration
        ))
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            // Pure black canvas — fills behind the status bar too.
            Color.black.ignoresSafeArea()

            mainComponent
                .offset(y: max(0, vm.dragOffset))
                .opacity(1 - vm.dragProgress * 0.35)
                .gesture(dragToDismissGesture)
                .onAppear {
                    if vm.uploadState.progress == 1.0 {
                        vm.uploadState.progress = nil
                    }
                }
                .disabled(vm.uploadState.progress ?? 0 > 0)

            if let progress = vm.uploadState.progress {
                VStack {
                    Spacer()
                    ProgressRingOverlayView(progress: progress, title: "Uploading")
                        .padding()
                        .opacity(progress < 1.0 ? 1 : 0)
                        .animation(.easeOut(duration: 0.3), value: progress)
                        .onChangeCompat(of: progress) { newProgress in
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
        // In glass mode, force dark appearance so materials render as dark frosted glass
        // and white icons/text are always legible against the black canvas.
        // In classic (tinted) mode, follow the system color scheme.
        .preferredColorScheme(vm.config.isGlassMode ? .dark : nil)
        // Sync ViewModel mutations back to caller's bindings.
        .onChangeCompat(of: vm.assets) { externalAssets = $0 }
        .onChangeCompat(of: vm.mediaAssets) { externalMediaAssets = $0 }
    }

    // MARK: - Subviews

    private var mainComponent: some View {
        VStack(spacing: 0) {
            TopBar(config: TopBarConfig(
                showEditButton: vm.config.showEditButton && vm.currentPhotoAsset != nil,
                showSelectButton: vm.totalCount > 1,
                selectionMode: vm.selectionMode,
                pageCounterText: vm.pageCounterText,
                accessibilityPageLabel: vm.accessibilityPageCounterText,
                tintColor: vm.config.resolvedTintColor,
                isGlassMode: vm.config.isGlassMode,
                onDismiss: { dismiss(); vm.delegate?.didTapCloseButton() },
                onCancelSelection: { vm.cancelSelection() },
                onSelectToggle: { vm.selectionMode = true },
                onEdit: {
                    guard let asset = vm.currentPhotoAsset else { return }
                    vm.delegate?.didTapEditButton(photo: asset)
                }
            ))

            ZStack {
                contentView
                if vm.selectionMode {
                    let gridItems: [MediaAsset] = vm.usesMediaMode
                        ? vm.mediaAssets
                        : vm.assets.map { MediaAsset.photo($0) }
                    MultiPhotoGrid(
                        mediaItems: gridItems,
                        selectedIndices: vm.selectedIndices,
                        selectionMode: vm.selectionMode,
                        onSelectToggle: { vm.handleSelection($0) }
                    )
                    .background(.regularMaterial)
                    .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.2), value: vm.selectionMode)

            if !vm.selectionMode {
                PageDotsView(currentIndex: vm.currentIndex, count: vm.totalCount)
            }

            BottomBar(comment: $vm.comment, config: BottomBarConfig(
                selectionMode: vm.selectionMode,
                showSaveButton: vm.shouldShowSaveButton,
                showCommentBox: vm.config.showCommentBox,
                title: vm.config.title,
                tintColor: vm.config.resolvedTintColor,
                isGlassMode: vm.config.isGlassMode,
                onSave: { vm.handleSave() },
                onDelete: { vm.handleDelete() }
            ))
        }
        .onChangeCompat(of: vm.currentPhotoAsset?.image) { newImage in
            guard newImage != nil else { return }
            vm.wasImageEdited = true
        }
        .onChangeCompat(of: vm.totalCount) { newCount in
            if newCount == 0 {
                dismiss()
            } else {
                vm.currentIndex = min(vm.currentIndex, newCount - 1)
            }
        }
        .onChangeCompat(of: vm.selectionMode) { _ in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                vm.dragOffset = 0
            }
        }
    }

    // MARK: - Drag-to-Dismiss Gesture

    private var dragToDismissGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard !vm.selectionMode, vm.uploadState.progress == nil else { return }
                let translation = value.translation
                // Activate only for predominantly downward drags to avoid
                // conflicting with horizontal TabView paging.
                guard translation.height > 0,
                      translation.height > abs(translation.width) * 1.5 else { return }
                vm.dragOffset = translation.height
            }
            .onEnded { value in
                let rawHeight = value.translation.height
                let predictedHeight = value.predictedEndTranslation.height
                let shouldDismiss = rawHeight > vm.dismissThreshold
                    || predictedHeight > vm.dismissThreshold

                if shouldDismiss {
                    withAnimation(.easeOut(duration: 0.25)) {
                        vm.dragOffset = UIScreen.main.bounds.height
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        dismiss()
                        vm.delegate?.didTapCloseButton()
                    }
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        vm.dragOffset = 0
                    }
                }
            }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if vm.usesMediaMode {
            if !vm.mediaAssets.isEmpty {
                TabView(selection: $vm.currentIndex) {
                    ForEach(Array(vm.mediaAssets.enumerated()), id: \.1.id) { index, item in
                        Group {
                            switch item.kind {
                            case .photo(let asset):
                                PhotoView(
                                    photo: asset,
                                    isSinglePhotoMode: true,
                                    tintColor: vm.config.resolvedTintColor,
                                    placeholderView: vm.config.placeholderView,
                                    errorView: vm.config.errorView
                                )
                                .padding(.horizontal)
                            case .video(let url):
                                VideoPlayerView(videoURL: url)
                                    .padding()
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        } else if let videoURL = vm.selectedVideo {
            VideoPlayerView(videoURL: videoURL)
                .padding()
        } else if !vm.assets.isEmpty {
            TabView(selection: $vm.currentIndex) {
                ForEach(Array(vm.assets.enumerated()), id: \.1.id) { index, asset in
                    PhotoView(
                        photo: asset,
                        isSinglePhotoMode: true,
                        tintColor: vm.config.resolvedTintColor,
                        placeholderView: vm.config.placeholderView,
                        errorView: vm.config.errorView
                    )
                    .padding(.horizontal)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
}

// MARK: - Array Extension

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Previews

private struct SinglePhotoPreview: View {
    @State private var assets: [PhotoAsset] = [PhotoAsset(image: UIImage(systemName: "person")!)]
    @State private var selectedVideo: URL? = nil
    var body: some View {
        HImageViewer(assets: $assets, selectedVideo: $selectedVideo)
    }
}

private struct MultiPhotoPreview: View {
    @State private var assets: [PhotoAsset] = (0..<5).map { _ in PhotoAsset(image: UIImage(systemName: "person")!) }
    @State private var selectedVideo: URL? = nil
    var body: some View {
        HImageViewer(assets: $assets, selectedVideo: $selectedVideo)
    }
}

private struct MixedMediaPreview: View {
    @State private var items: [MediaAsset] = [
        .photo(PhotoAsset(image: UIImage(systemName: "photo")!)),
        .photo(PhotoAsset(image: UIImage(systemName: "star")!))
    ]
    var body: some View {
        HImageViewer(mediaAssets: $items)
    }
}

#Preview("Single")      { SinglePhotoPreview() }
#Preview("Multi")       { MultiPhotoPreview() }
#Preview("Mixed Media") { MixedMediaPreview() }
