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

    /// Automatically `true` when the hosting controller is pushed onto a
    /// UINavigationController rather than presented modally.
    @State private var isInNavigationStack: Bool = false

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
            // Canvas — fills behind the status bar too.
            // Defaults to systemBackground so it adapts to light/dark mode automatically.
            vm.config.backgroundColor.ignoresSafeArea()

            // Invisible detector — reads the UIKit responder chain on appear
            // to decide whether this hosting controller is pushed or presented.
            NavigationDetector { isPushed in
                isInNavigationStack = isPushed
            }
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)

            mainComponent
                .offset(y: max(0, vm.dragOffset))
                .opacity(1 - vm.dragProgress * 0.35)
                // Drag-to-dismiss is a modal pattern only.
                // When pushed onto a navigation stack the system's swipe-back
                // gesture already handles dismissal, so we skip ours entirely.
                .simultaneousGesture(isInNavigationStack ? nil : dragToDismissGesture)
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
        // Follow the system color scheme in all modes.
        // Glass materials (.glassEffect / .ultraThinMaterial) and .primary foreground
        // colors adapt automatically — no forced dark override needed.
        // Sync ViewModel mutations back to caller's bindings.
        .onChangeCompat(of: vm.assets) { externalAssets = $0 }
        .onChangeCompat(of: vm.mediaAssets) { externalMediaAssets = $0 }
        // When pushed onto a UINavigationController, populate the system nav bar
        // instead of rendering our own top bar (see mainComponent for the other half).
        //
        // Note: `if` at the top level of .toolbar{} requires ToolbarContentBuilder.buildIf
        // which is iOS 16+. We keep the top-level items unconditional and gate
        // their @ViewBuilder content on `isInNavigationStack` instead — that `if`
        // is plain @ViewBuilder, available on iOS 15.
        .toolbar {
            // Centred page counter: "2 / 5"
            ToolbarItem(placement: .principal) {
                if isInNavigationStack, let counter = vm.pageCounterText {
                    Text(counter)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .accessibilityLabel(vm.accessibilityPageCounterText ?? counter)
                }
            }

            // Trailing action buttons
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if isInNavigationStack {
                    // Glass mode: match the native back-button appearance (label color,
                    // black in light / white in dark). Classic mode: use the custom tint.
                    let buttonTint: Color = vm.config.isGlassMode
                        ? Color(.label)
                        : vm.config.resolvedTintColor
                    if vm.selectionMode {
                        Button("Cancel", action: vm.cancelSelection)
                            .font(.body.weight(.medium))
                            .foregroundStyle(buttonTint)
                            .accessibilityHint("Exits selection mode")
                    } else {
                        if vm.config.showEditButton && vm.currentPhotoAsset != nil {
                            Button {
                                guard let asset = vm.currentPhotoAsset else { return }
                                vm.delegate?.didTapEditButton(photo: asset)
                            } label: {
                                Image(systemName: "pencil")
                            }
                            .tint(buttonTint)
                            .accessibilityLabel("Edit")
                            .accessibilityHint("Opens the photo editor")
                        }
                        if vm.totalCount > 1 {
                            Button { vm.selectionMode = true } label: {
                                Image(systemName: "checkmark.circle")
                            }
                            .tint(buttonTint)
                            .accessibilityLabel("Select")
                            .accessibilityHint("Enters selection mode")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var mainComponent: some View {
        VStack(spacing: 0) {
            // When pushed, the system navigation bar owns the top row —
            // controls are populated via .toolbar in body. No custom bar needed.
            if !isInNavigationStack {
                TopBar(config: TopBarConfig(
                    showCloseButton: true,
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
            }

            ZStack {
                if vm.selectionMode {
                    let gridItems: [MediaAsset] = vm.usesMediaMode
                        ? vm.mediaAssets
                        : vm.assets.map { MediaAsset.photo($0) }
                    ScrollView {
                        MultiPhotoGrid(
                            mediaItems: gridItems,
                            selectedIndices: vm.selectedIndices,
                            selectionMode: vm.selectionMode,
                            onSelectToggle: { vm.handleSelection($0) },
                            onReorder: { from, to in vm.reorderItems(from: from, to: to) }
                        )
                    }
                    .transition(.opacity)
                } else {
                    contentView
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
                    vm.haptics.impact(.light)
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

// MARK: - Navigation Detection

/// A zero-size UIViewRepresentable that detects whether its hosting
/// UIViewController is pushed onto a UINavigationController.
///
/// It walks the UIKit responder chain on `didMoveToWindow` and calls
/// `onDetect(true)` when a navigation controller is found, `false` otherwise.
/// This lets `HImageViewer` auto-hide its X close button when pushed, since
/// the navigation back button already handles dismissal.
private struct NavigationDetector: UIViewRepresentable {

    var onDetect: (Bool) -> Void

    func makeUIView(context: Context) -> _DetectorView {
        _DetectorView(onDetect: onDetect)
    }

    func updateUIView(_ uiView: _DetectorView, context: Context) {
        uiView.onDetect = onDetect
    }

    // MARK: - Internal UIView

    final class _DetectorView: UIView {

        var onDetect: (Bool) -> Void

        init(onDetect: @escaping (Bool) -> Void) {
            self.onDetect = onDetect
            super.init(frame: .zero)
            backgroundColor = .clear
            isUserInteractionEnabled = false
        }

        required init?(coder: NSCoder) { fatalError("not used") }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil else { return }
            // Defer one runloop tick so the VC hierarchy is fully assembled.
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let isPushed = self.parentViewController?.navigationController != nil
                self.onDetect(isPushed)
            }
        }

        /// Walks the UIKit responder chain to find the nearest UIViewController.
        private var parentViewController: UIViewController? {
            var responder: UIResponder? = next
            while let r = responder {
                if let vc = r as? UIViewController { return vc }
                responder = r.next
            }
            return nil
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
