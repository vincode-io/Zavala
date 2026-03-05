// swift-tools-version: 6.0

import PackageDescription

let package = Package(
	name: "VinOutlineKit",
	defaultLocalization: "en",
	platforms: [.macOS(.v15), .iOS(.v18)],
	products: [
		.library(
			name: "VinOutlineKit",
			targets: ["VinOutlineKit"]),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-markdown.git", branch: "main"),
		.package(url: "https://github.com/groue/Semaphore.git", branch: "main"),
		.package(url: "https://github.com/vincode-io/VinXML.git", branch: "release"),
		.package(url: "https://github.com/vincode-io/VinCloudKit.git", branch: "release"),
		.package(path: "../VinMarkdown"),
	],
	targets: [
		.target(
			name: "VinOutlineKit",
			dependencies: [
				.product(name: "Markdown", package: "swift-markdown"),
				"Semaphore",
				"VinXML",
				"VinCloudKit",
				"VinMarkdown",
			],
		),
		.testTarget(
			name: "VinOutlineKitTests",
			dependencies: [
				"VinOutlineKit",
			],
			resources: [.copy("Resources")]
		),
	]
)
