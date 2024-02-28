// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VinUtility",
	defaultLocalization: "en",
	platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(
            name: "VinUtility",
            targets: ["VinUtility"]),
    ],
	dependencies: [
		.package(url: "https://github.com/apple/swift-collections.git", .upToNextMajor(from: "1.0.2")),
		.package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0"),
	],
	targets: [
        .target(
            name: "VinUtility",
		dependencies: [
			.product(name: "OrderedCollections", package: "swift-collections"),
			.product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
		]
//		swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
	),
	]
)
