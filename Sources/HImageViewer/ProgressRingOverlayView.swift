//
//  ProgressRingView.swift
//  HImageViewer
//
//  Created by Hamza Khalid on 11/07/2025.
//

import SwiftUI

struct ProgressRingOverlayView: View {
    var progress: Double // 0.0 ... 1.0
    var title: String?

    var body: some View {
        VStack(spacing: 8) {
            if let title {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            

            ZStack {
                Circle()
                    .stroke(lineWidth: 6)
                    .opacity(0.2)
                    .foregroundColor(.gray)

                Circle()
                    .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.blue, .green]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(Angle(degrees: -90))
                    .animation(.easeInOut, value: progress)

                Text(String(format: "%.0f%%", progress * 100))
                    .font(.caption)
                    .bold()
            }
            .frame(width: 60, height: 60)
            .padding(8)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 1)
    }
}
#Preview {
    ProgressRingOverlayView(progress: 0.6, title: "Uploading")
}

