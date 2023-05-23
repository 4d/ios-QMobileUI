// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "QMobileUI",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v14)
    ],
    products: [
        .library(name: "QMobileUI", targets: ["QMobileUI"])
    ],
    dependencies: [
        .package(url: "https://github.com/phimage/CallbackURLKit.git", .revision("HEAD")),
        .package(url: "https://github.com/nvzqz/FileKit.git", from: "6.1.0"),
        .package(url: "https://github.com/DaveWoodCom/XCGLogger.git", from: "7.0.0"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.14"),
        .package(url: "https://github.com/phimage/ValueTransformerKit.git", from: "1.2.4"),
        .package(url: "https://github.com/phimage/Prephirences.git", from: "5.4.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "6.2.1"),

//        .package(url: "https://github.com/SwiftKickMobile/SwiftMessages.git", from: "7.0.0"), // No Package.swift file
        .package(url: "https://github.com/phimage/SwiftMessages.git", .revision("HEAD")), // https://github.com/SwiftKickMobile/SwiftMessages/pull/297
        .package(url: "https://github.com/xmartlabs/Eureka.git", from: "5.3.6"),
        .package(url: "https://github.com/IBAnimatable/IBAnimatable.git", from: "6.1.0"),

        .package(url: "https://github.com/4d/ios-QMobileAPI.git", .revision("HEAD")),
        .package(url: "https://github.com/4d/ios-QMobileDataStore.git", .revision("HEAD")),
        .package(url: "https://github.com/4d/ios-QMobileDataSync.git", .revision("HEAD"))
    ],
    targets: [
        .target(
            name: "QMobileUI",
            dependencies: [
                "FileKit",
                "XCGLogger",
                "ZIPFoundation",
                "Prephirences",
                "ValueTransformerKit",
                "SwiftMessages",
                "Eureka",
                "IBAnimatable",
                "Kingfisher",
                .product(name: "QMobileAPI", package: "ios-QMobileAPI"),
                .product(name: "QMobileDataStore", package: "ios-QMobileDataStore"),
                .product(name: "QMobileDataSync", package: "ios-QMobileDataSync"),
                "CallbackURLKit"
            ],
            path: "Sources"),
        .testTarget(
            name: "QMobileUITests",
            dependencies: ["QMobileUI"],
            path: "Tests")
    ]
)
