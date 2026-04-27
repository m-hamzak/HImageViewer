// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "HImageViewer",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "HImageViewer",
            targets: ["HImageViewer"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "HImageViewer",
            dependencies: [],
            path: "Sources/HImageViewer"
        ),
        .testTarget(
            name: "HImageViewerTests",
            dependencies: ["HImageViewer"],
            path: "Tests/HImageViewerTests"
        )
    ]
)
