//
//  ZoomableImageView.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 19/04/2026.
//

import SwiftUI

/// Zoom range constants — isolated to a plain enum to avoid @MainActor constraints.
enum ZoomDefaults {
    static let minScale: CGFloat = 1.0
    static let maxScale: CGFloat = 5.0
    static let doubleTapScale: CGFloat = 2.5
}

struct ZoomableImageView: View {

    let image: UIImage

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .contentShape(Rectangle())
                .onTapGesture(count: 2) { handleDoubleTap() }
                .gesture(magnificationGesture)
                .simultaneousGesture(dragGesture(in: geometry))
        }
    }

    // MARK: - Gesture Handlers

    private func handleDoubleTap() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            scale = zoomToggle(current: scale)
            if scale == ZoomDefaults.minScale {
                offset = .zero
                lastOffset = .zero
            }
            lastScale = scale
        }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = zoomClamp(lastScale * value)
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    scale = zoomClamp(scale)
                    if scale == ZoomDefaults.minScale {
                        offset = .zero
                        lastOffset = .zero
                    }
                }
                lastScale = scale
            }
    }

    private func dragGesture(in geometry: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard scale > ZoomDefaults.minScale else { return }
                let proposed = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
                offset = panClamp(proposed, scale: scale, in: geometry.size)
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }
}

// MARK: - Pure helpers (internal, tested independently)

/// Clamps a zoom scale to the allowed range.
func zoomClamp(
    _ scale: CGFloat,
    min: CGFloat = ZoomDefaults.minScale,
    max: CGFloat = ZoomDefaults.maxScale
) -> CGFloat {
    Swift.min(Swift.max(scale, min), max)
}

/// Returns the toggled scale for a double-tap: resets to min if zoomed in, zooms to tapTarget otherwise.
func zoomToggle(
    current: CGFloat,
    tapTarget: CGFloat = ZoomDefaults.doubleTapScale
) -> CGFloat {
    current > ZoomDefaults.minScale ? ZoomDefaults.minScale : tapTarget
}

/// Clamps a pan offset so the image cannot be dragged beyond its scaled bounds.
func panClamp(_ offset: CGSize, scale: CGFloat, in containerSize: CGSize) -> CGSize {
    let maxX = (containerSize.width * (scale - 1)) / 2
    let maxY = (containerSize.height * (scale - 1)) / 2
    return CGSize(
        width: Swift.min(Swift.max(offset.width, -maxX), maxX),
        height: Swift.min(Swift.max(offset.height, -maxY), maxY)
    )
}
