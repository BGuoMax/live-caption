// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "LiveCaption",
    platforms: [
        .macOS("15.0")
    ],
    products: [
        .executable(name: "LiveCaption", targets: ["LiveCaption"])
    ],
    targets: [
        .executableTarget(
            name: "LiveCaption",
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("ScreenCaptureKit"),
                .linkedFramework("Speech"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("Translation")
            ]
        ),
        .testTarget(
            name: "LiveCaptionTests",
            dependencies: ["LiveCaption"]
        )
    ]
)
