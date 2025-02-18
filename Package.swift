// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "CombineWamp",
    platforms: [.iOS(.v13), .tvOS(.v13), .macOS(.v10_15), .watchOS(.v6)],
    products: [
        .library(name: "CombineWamp", targets: ["CombineWamp"])
    ],
    dependencies: [
        .package(url: "https://github.com/FastSkipper-com/CombineWebSocket.git", .upToNextMajor(from: "0.1.1")),
        .package(url: "https://github.com/FastSkipper-com/FoundationExtensions.git", .upToNextMajor(from: "0.1.1"))
    ],
    targets: [
        .target(
            name: "CombineWamp",
            dependencies: [
                "CombineWebSocket",
                .product(name: "FoundationExtensions", package: "FoundationExtensions")
            ]
        ),
        .testTarget(name: "CombineWampTests", dependencies: ["CombineWamp"]),
        .testTarget(name: "CombineWampIntegrationTests", dependencies: ["CombineWamp"])
    ]
)
