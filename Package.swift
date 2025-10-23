// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WiFi-Optimizer",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "WiFi-Optimizer",
            targets: ["WiFi-Optimizer"]),
        .executable(
            name: "wifiopt-cli",
            targets: ["wifiopt-cli"]
        ),
        .executable(
            name: "wifiopt-app",
            targets: ["wifiopt-app"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "WiFi-Optimizer",
            linkerSettings: [
                .linkedFramework("CoreWLAN")
            ]
        ),
        .executableTarget(
            name: "wifiopt-cli",
            dependencies: ["WiFi-Optimizer"],
            linkerSettings: [
                .linkedFramework("CoreWLAN")
            ]
        ),
        .executableTarget(
            name: "wifiopt-app",
            dependencies: ["WiFi-Optimizer"],
            resources: [
                .process("wifiopt-app.entitlements")
            ],
            linkerSettings: [
                .linkedFramework("CoreWLAN"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("AppKit"),
                .linkedFramework("CoreLocation")
            ]
        ),
        .testTarget(
            name: "WiFi-OptimizerTests",
            dependencies: ["WiFi-Optimizer"]
        ),
    ]
)
