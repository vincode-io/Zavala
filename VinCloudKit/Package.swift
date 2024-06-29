// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VinCloudKit",
	defaultLocalization: "en",
	platforms: [.macOS(.v13), .iOS(.v16)],
	products: [
		.library(
			name: "VinCloudKit",
			targets: ["VinCloudKit"]),
	],
	dependencies: [
		.package(path: "../VinUtility"),
	],
	targets: [
		.target(
			name: "VinCloudKit",             
			dependencies: [
				"VinUtility",
			],
			swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
		),
	]
)
