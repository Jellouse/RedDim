// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RedDim",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "RedDim", targets: ["RedDim"])
    ],
    targets: [
        .executableTarget(
            name: "RedDim",
            path: "Sources/RedDim",
            linkerSettings: [
                .linkedFramework("ScreenCaptureKit"),
                .linkedFramework("CoreImage"),
                .linkedFramework("AppKit")
            ]
        )
    ]
)
