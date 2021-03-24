// swift-tools-version:5.3

// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Developer on 12/01/2021.
//  All code (c) 2021 - present day, Sam Developer.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import PackageDescription

let package = Package(
    name: "BookishImporter",
    platforms: [
        .macOS(.v10_13), .iOS(.v13)
    ],
    products: [
        .library(
            name: "BookishImporter",
            targets: ["BookishImporter"]),
        .library(
            name: "BookishImporterSamples",
            targets: ["BookishImporterSamples"]),
    ],
    dependencies: [
        .package(url: "https://github.com/elegantchaos/Files.git", from: "1.1.4"),
        .package(url: "https://github.com/elegantchaos/Localization.git", from: "1.0.3"),
        .package(url: "https://github.com/elegantchaos/Logger.git", from: "1.5.7"),
        .package(url: "https://github.com/elegantchaos/ISBN", from: "1.0.0"),
        .package(url: "https://github.com/elegantchaos/XCTestExtensions.git", from: "1.1.2"),
    ],
    targets: [
        .target(
            name: "BookishImporter",
            dependencies: ["Files", "ISBN", "Localization" ,"Logger"]
        ),
        
        .target(
            name: "BookishImporterSamples",
            dependencies: [],
            resources: [
                .process("Resources")
            ]
        ),
        
        .testTarget(
            name: "BookishImporterTests",
            dependencies: ["BookishImporter", "BookishImporterSamples", "XCTestExtensions"]),
    ]
)
