// swift-tools-version: 6.0

import PackageDescription

let package = Package(
	name: "VinOutlineKit",
	defaultLocalization: "en",
	platforms: [.macOS(.v13), .iOS(.v16)],
	products: [
		.library(
			name: "VinOutlineKit",
			targets: ["VinOutlineKit"]),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-markdown.git", branch: "main"),
		.package(url: "https://github.com/vincode-io/MarkdownAttributedString.git", branch: "master"),
		.package(url: "https://github.com/groue/Semaphore.git", branch: "main"),
		.package(url: "https://github.com/vincode-io/VinXML.git", branch: "release"),
		.package(url: "https://github.com/vincode-io/VinCloudKit.git", branch: "release"),
	],
	targets: [
		.target(
			name: "VinOutlineKit",
			dependencies: [
				.product(name: "Markdown", package: "swift-markdown"),
				"MarkdownAttributedString",
				"Semaphore",
				"VinXML",
				"VinCloudKit",
			],
			swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
		),
		.testTarget(
			name: "VinOutlineKitTests",
			dependencies: [
				"VinOutlineKit",
			],
			resources: [.copy("Resources")
		]),
	]
)
