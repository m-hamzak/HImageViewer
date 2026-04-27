import SwiftUI
import HImageViewer

// MARK: - Root navigation

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                Section("SwiftUI") {
                    NavigationLink("Photo Gallery",      destination: PhotoGalleryExample())
                    NavigationLink("Mixed Media",        destination: MixedMediaExample())
                    NavigationLink("Remote Images",      destination: RemoteImagesExample())
                    NavigationLink("Glass Theme",        destination: GlassThemeExample())
                    NavigationLink("Classic Theme",      destination: ClassicThemeExample())
                    NavigationLink("Upload Progress",    destination: UploadProgressExample())
                    NavigationLink("With Delegate",      destination: DelegateExample())
                    NavigationLink("Photo Captions",     destination: CaptionsExample())
                    NavigationLink("Haptic & Share",     destination: HapticShareExample())
                    NavigationLink("Context Menu",       destination: ContextMenuExample())
                }
                Section("UIKit") {
                    NavigationLink("UIKit Launcher",     destination: UIKitLauncherExample())
                }
            }
            .navigationTitle("HImageViewer")
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Photo Gallery

struct PhotoGalleryExample: View {
    @State private var items: [MediaAsset] = MediaAsset.from(uiImages: [
        sym("photo"),
        sym("photo.fill"),
        sym("photo.on.rectangle"),
        sym("photo.stack"),
    ])
    @State private var isPresented = false

    var body: some View {
        VStack(spacing: 24) {
            Text("\(items.count) items in gallery")
                .foregroundStyle(.secondary)
            Button("Open Gallery") { isPresented = true }
                .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Photo Gallery")
        .fullScreenCover(isPresented: $isPresented) {
            HImageViewer(mediaAssets: $items)
        }
    }
}

// MARK: - Mixed Media

struct MixedMediaExample: View {
    @State private var items: [MediaAsset] = [
        .photo(PhotoAsset(image: sym("photo"))),
        .video(URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!),
        .photo(PhotoAsset(image: sym("star"))),
    ]
    @State private var isPresented = false

    var body: some View {
        VStack(spacing: 24) {
            Text("2 photos + 1 video")
                .foregroundStyle(.secondary)
            Button("Open Mixed Gallery") { isPresented = true }
                .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Mixed Media")
        .fullScreenCover(isPresented: $isPresented) {
            HImageViewer(mediaAssets: $items)
        }
    }
}

// MARK: - Remote Images

struct RemoteImagesExample: View {
    @State private var items: [MediaAsset] = [
        .photo(PhotoAsset(imageURL: URL(string: "https://picsum.photos/800/600?random=1")!)),
        .photo(PhotoAsset(imageURL: URL(string: "https://picsum.photos/800/600?random=2")!)),
        .photo(PhotoAsset(imageURL: URL(string: "https://picsum.photos/800/600?random=3")!)),
    ]
    @State private var isPresented = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Fetched from picsum.photos")
                .foregroundStyle(.secondary)
            Button("Open Remote Gallery") { isPresented = true }
                .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Remote Images")
        .fullScreenCover(isPresented: $isPresented) {
            HImageViewer(mediaAssets: $items)
        }
    }
}

// MARK: - Glass Theme (default)

struct GlassThemeExample: View {
    @State private var items = MediaAsset.from(uiImages: Array(repeating: sym("photo"), count: 3))
    @State private var isPresented = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Default theme — Liquid Glass controls")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Open") { isPresented = true }
                .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Glass Theme")
        .fullScreenCover(isPresented: $isPresented) {
            HImageViewer(mediaAssets: $items)   // tintColor nil → Glass mode (default)
        }
    }
}

// MARK: - Classic Theme

struct ClassicThemeExample: View {
    @State private var items = MediaAsset.from(uiImages: Array(repeating: sym("photo"), count: 3))
    @State private var isPresented = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Classic theme with orange tint")
                .foregroundStyle(.secondary)
            Button("Open") { isPresented = true }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
        }
        .navigationTitle("Classic Theme")
        .fullScreenCover(isPresented: $isPresented) {
            HImageViewer(
                mediaAssets: $items,
                configuration: HImageViewerConfiguration(tintColor: .orange)
            )
        }
    }
}

// MARK: - Upload Progress

struct UploadProgressExample: View {
    @State private var items = MediaAsset.from(uiImages: [sym("photo")])
    @State private var isPresented = false
    @StateObject private var uploadState = HImageViewerUploadState()

    var body: some View {
        VStack(spacing: 24) {
            Text("Simulates an upload with animated ring.\nViewer auto-dismisses at 100%.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Open & Simulate Upload") {
                isPresented = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    simulateUpload()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Upload Progress")
        .fullScreenCover(isPresented: $isPresented) {
            HImageViewer(
                mediaAssets: $items,
                configuration: HImageViewerConfiguration(uploadState: uploadState)
            )
        }
    }

    private func simulateUpload() {
        var p = 0.0
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            p = min(p + 0.04, 1.0)
            uploadState.progress = p
            if p >= 1.0 { timer.invalidate() }
        }
    }
}

// MARK: - Delegate Example

final class ExampleDelegate: HImageViewerControlDelegate {
    var lastAction: String = "—"

    func didTapSaveButton(comment: String, photos: [PhotoAsset]) {
        lastAction = "Save tapped. Comment: \"\(comment)\", photos: \(photos.count)"
    }

    func didTapCloseButton() {
        lastAction = "Close tapped"
    }

    func didDeleteMediaAssets(_ assets: [MediaAsset]) {
        lastAction = "Deleted \(assets.count) item(s)"
    }

    func didChangePage(to index: Int) {
        lastAction = "Page changed to \(index)"
    }

    func didTapShareButton(photos: [PhotoAsset]) {
        lastAction = "Share tapped — \(photos.count) photo(s)"
    }
}

struct DelegateExample: View {
    @State private var items = MediaAsset.from(uiImages: [
        sym("photo"),
        sym("star"),
        sym("heart"),
    ])
    @State private var isPresented = false
    @State private var lastAction = "—"
    private let delegate = ExampleDelegate()

    var body: some View {
        VStack(spacing: 24) {
            Text("Last action:\n\(lastAction)")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Open") { isPresented = true }
                .buttonStyle(.borderedProminent)
        }
        .navigationTitle("With Delegate")
        .fullScreenCover(isPresented: $isPresented) {
            HImageViewer(
                mediaAssets: $items,
                configuration: HImageViewerConfiguration(
                    showSaveButton: true,
                    showCommentBox: true,
                    delegate: delegate
                )
            )
        }
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            lastAction = delegate.lastAction
        }
    }
}

// MARK: - Photo Captions

struct CaptionsExample: View {
    @State private var items: [MediaAsset] = [
        .photo(PhotoAsset(image: sym("photo"),
                          caption: "Landscape shot — double-tap to zoom")),
        .photo(PhotoAsset(image: sym("star.fill"),
                          caption: "Starred favourite")),
        .photo(PhotoAsset(image: sym("heart.fill"),
                          caption: "Most liked photo of the week")),
    ]
    @State private var isPresented = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Each photo has an individual caption\nvisible below the image.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Open with Captions") { isPresented = true }
                .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Photo Captions")
        .fullScreenCover(isPresented: $isPresented) {
            HImageViewer(mediaAssets: $items)
        }
    }
}

// MARK: - Haptic & Share

struct HapticShareExample: View {
    @State private var items: [MediaAsset] = MediaAsset.from(uiImages: [
        sym("photo"),
        sym("photo.fill"),
        sym("photo.on.rectangle"),
        sym("photo.stack"),
    ])
    @State private var isPresented = false

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Label("Share button in top bar", systemImage: "square.and.arrow.up")
                Label("Selection haptic on every swipe", systemImage: "hand.tap")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Button("Open") { isPresented = true }
                .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Haptic & Share")
        .fullScreenCover(isPresented: $isPresented) {
            HImageViewer(
                mediaAssets: $items,
                configuration: HImageViewerConfiguration(
                    showShareButton: true,   // share button (also the default)
                    pageChangeHaptic: true   // selection pulse on every page swipe
                )
            )
        }
    }
}

// MARK: - Context Menu

struct ContextMenuExample: View {
    @State private var items: [MediaAsset] = [
        .photo(PhotoAsset(image: sym("photo"),
                          caption: "Long-press for options")),
        .photo(PhotoAsset(image: sym("photo.fill"),
                          caption: "Copy · Share · Save to Photos")),
        .photo(PhotoAsset(image: sym("photo.stack"),
                          caption: "Works on every photo")),
    ]
    @State private var isPresented = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Long-press any photo to Copy, Share,\nor Save to Photos.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Open") { isPresented = true }
                .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Context Menu")
        .fullScreenCover(isPresented: $isPresented) {
            HImageViewer(
                mediaAssets: $items,
                configuration: HImageViewerConfiguration(
                    showContextMenu: true   // long-press context menu (also the default)
                )
            )
        }
    }
}

// MARK: - UIKit Launcher

struct UIKitLauncherExample: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIKitExampleViewController {
        UIKitExampleViewController()
    }
    func updateUIViewController(_ vc: UIKitExampleViewController, context: Context) {}
}

// MARK: - Helpers

/// Creates an SF Symbol `UIImage` rasterised at 300 pt so it displays crisply
/// at full-screen size without upscaling blur. Only used in the example app —
/// real apps supply actual photos which are already high-resolution.
private func sym(_ name: String) -> UIImage {
    let config = UIImage.SymbolConfiguration(pointSize: 300, weight: .regular, scale: .large)
    return UIImage(systemName: name, withConfiguration: config) ?? UIImage()
}
