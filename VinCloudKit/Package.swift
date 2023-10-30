// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VinCloudKit",
	platforms: [.macOS(SupportedPlatform.MacOSVersion.v11), .iOS(SupportedPlatform.IOSVersion.v14)],
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
			])
	]
)
