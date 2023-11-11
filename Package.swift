// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SafariDownload",
    platforms: [.macOS(.v13)],
    products: [
        .library(
            name: "SafariDownload",
            targets: ["SafariDownload"]
        ),
    ],
    targets: [
        .target(
            name: "SafariDownload",
            dependencies: []
        ),
        .testTarget(
            name: "SafariDownloadTests",
            dependencies: ["SafariDownload"],
            resources: [.copy("Resources/Xcode_15.0.1.xip.download")]
        ),
    ]
)
