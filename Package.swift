// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "QMobileUI",
    platforms: [
        .macOS(.v10_14),
        .iOS(.v13)
    ],
    products: [
        .library(name: "QMobileUI", targets: ["QMobileUI"])
    ],
    dependencies: [
        .package(url: "https://github.com/phimage/CallbackURLKit.git", .revision("HEAD")),
        .package(url: "https://github.com/nvzqz/FileKit.git", from: "6.0.0"),
        .package(url: "https://github.com/DaveWoodCom/XCGLogger.git", from: "7.0.0"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.9"),
        .package(url: "https://github.com/Thomvis/BrightFutures.git", from: "8.0.1"),
        .package(url: "https://github.com/ArtSabintsev/Guitar.git", from: "1.1.0"),
        .package(url: "https://github.com/phimage/ValueTransformerKit.git", from: "1.2.3"),
        .package(url: "https://github.com/phimage/Prephirences.git", from: "5.1.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "5.8.1"),

//         .package(url: "https://github.com/devicekit/DeviceKit.git", from: "2.3.0"), // no mac support
        .package(url: "https://github.com/phimage/DeviceKit.git", .branch("feature/macos")), // https://github.com/devicekit/DeviceKit/pull/217
//        .package(url: "https://github.com/SwiftKickMobile/SwiftMessages.git", from: "7.0.0"), // No Package.swift file
        .package(url: "https://github.com/phimage/SwiftMessages.git", .revision("HEAD")), // https://github.com/SwiftKickMobile/SwiftMessages/pull/297
//        .package(url: "https://github.com/xmartlabs/Eureka.git", from: "5.0.0"), // No Package.swift file
        .package(url: "https://github.com/thebluepotato/Eureka.git", .branch("spm")), // https://github.com/xmartlabs/Eureka/pull/1877
        .package(url: "https://github.com/IBAnimatable/IBAnimatable.git", .revision("HEAD")),

        .package(url: "https://gitlab-4d.private.4d.fr/qmobile/QMobileAPI.git", .revision("HEAD")),
        .package(url: "https://gitlab-4d.private.4d.fr/qmobile/QMobileDataStore.git", .revision("HEAD")),
        .package(url: "https://gitlab-4d.private.4d.fr/qmobile/QMobileDataSync.git", .revision("HEAD"))
    ],
    targets: [
        .target(
            name: "QMobileUI",
            dependencies: [
                "FileKit",
                "XCGLogger",
                "ZIPFoundation",
                "BrightFutures",
                "Guitar",
                "Prephirences",
                "ValueTransformerKit",
                "SwiftMessages",
                "Eureka",
                "IBAnimatable",
                "DeviceKit",
                "Kingfisher",
                "QMobileAPI",
                "QMobileDataStore",
                "QMobileDataSync",
                "CallbackURLKit"
            ],
            path: "Sources"),
        .testTarget(
            name: "QMobileUITests",
            dependencies: ["QMobileUI"],
            path: "Tests")
    ]
)
