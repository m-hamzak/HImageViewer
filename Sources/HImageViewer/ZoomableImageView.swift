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
    /// Increment this value to animate the view back to default zoom (scale 1, offset zero).
    /// Pass the viewer's `currentIndex` so each page resets when the user navigates away.
    var resetToken: Int = 0

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .contentShape(Rectangle())
                // DoubleTapLocator overlays a UIKit recognizer that reports the
                // precise tap point — enabling zoom-to-point rather than zoom-to-center.
                .overlay(
                    DoubleTapLocator { tapPoint in
                        handleDoubleTap(at: tapPoint, in: geometry.size)
                    }
                )
                .gesture(magnificationGesture)
                // Only attach the pan drag while zoomed in — at scale 1.0 the
                // gesture would race with TabView's horizontal page-swipe.
                .simultaneousGesture(scale > ZoomDefaults.minScale ? dragGesture(in: geometry) : nil)
        }
        .onChangeCompat(of: resetToken) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                scale = ZoomDefaults.minScale
                lastScale = ZoomDefaults.minScale
                offset = .zero
                lastOffset = .zero
            }
        }
    }

    // MARK: - Gesture Handlers

    /// Toggles zoom, targeting the tapped point so that location stays centred on screen.
    ///
    /// **Zoom-in math:**
    /// After scaling by `s` around the image centre, a point at position `p` relative
    /// to the centre maps to `p × s` in parent coordinates. To bring `tapPoint` to the
    /// view centre we need `offset = (centre − tapPoint) × s`, then clamp within bounds.
    private func handleDoubleTap(at tapPoint: CGPoint, in containerSize: CGSize) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            let newScale = zoomToggle(current: scale)
            if newScale == ZoomDefaults.minScale {
                scale = ZoomDefaults.minScale
                offset = .zero
                lastOffset = .zero
            } else {
                scale = newScale
                let centre = CGPoint(x: containerSize.width / 2, y: containerSize.height / 2)
                let raw = CGSize(
                    width:  (centre.x - tapPoint.x) * newScale,
                    height: (centre.y - tapPoint.y) * newScale
                )
                offset = panClamp(raw, scale: newScale, in: containerSize)
                lastOffset = offset
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
