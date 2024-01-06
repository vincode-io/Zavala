// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VinUtility",
	defaultLocalization: "en",
	platforms: [.macOS(SupportedPlatform.MacOSVersion.v13), .iOS(SupportedPlatform.IOSVersion.v16)],
    products: [
        .library(
            name: "VinUtility",
            targets: ["VinUtility"]),
    ],
	dependencies: [
		.package(url: "https://github.com/apple/swift-collections.git", .upToNextMajor(from: "1.0.2")),
	],
	targets: [
        .target(
            name: "VinUtility",
		dependencies: [
			.product(name: "OrderedCollections", package: "swift-collections")
		]),
	]
)
