// swift-tools-version:5.2

// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Developer on 12/01/2021.
//  All code (c) 2021 - present day, Sam Developer.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import PackageDescription

let package = Package(
    name: "BookishImporter",
    platforms: [
        .macOS(.v10_13)
    ],
    products: [
        .library(
            name: "BookishImporter",
            targets: ["BookishImporter"]),
    ],
    dependencies: [
        .package(url: "https://github.com/elegantchaos/XCTestExtensions", from: "1.1.2")
    ],
    targets: [
        .target(
            name: "BookishImporter",
            dependencies: []),
        .testTarget(
            name: "BookishImporterTests",
            dependencies: ["BookishImporter", "XCTestExtensions"]),
    ]
)
