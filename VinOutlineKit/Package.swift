// swift-tools-version:5.9
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
		.package(url: "https://github.com/vincode-io/MarkdownAttributedString.git", branch: "master"),
		.package(url: "https://github.com/groue/Semaphore.git", branch: "main"),
		.package(url: "https://github.com/vincode-io/VinXML.git", branch: "main"),
		.package(path: "../VinCloudKit"),
	],
	targets: [
		.target(
			name: "VinOutlineKit",
			dependencies: [
				"MarkdownAttributedString",
				"Semaphore",
				"VinXML",
				"VinCloudKit",
		]),
		.testTarget(
			name: "VinOutlineTests",
			dependencies: [
				"VinOutlineKit",
//				"MarkdownAttributedString",
//				"Semaphore",
//				"VinXML",
//				"VinCloudKit",
			],
			resources: [.copy("Resources")
		]),
	]
)
