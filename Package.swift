// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GifBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "GifBar", targets: ["GifBar"])
    ],
    targets: [
        .executableTarget(
            name: "GifBar",
            path: "Sources/Santa"
        ),
        .testTarget(
            name: "SantaTests",
            dependencies: ["GifBar"],
            path: "Tests/SantaTests"
        )
    ]
)
