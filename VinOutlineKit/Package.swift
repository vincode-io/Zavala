// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "VinOutlineKit",
	defaultLocalization: "en",
	platforms: [.macOS(SupportedPlatform.MacOSVersion.v13), .iOS(SupportedPlatform.IOSVersion.v16)],
    products: [
        .library(
            name: "VinOutlineKit",
            targets: ["VinOutlineKit"]),
    ],
    dependencies: [
		.package(url: "https://github.com/vincode-io/MarkdownAttributedString.git", branch: "master"),
		.package(url: "https://github.com/vincode-io/VinXML.git", branch: "main"),
		.package(path: "../VinCloudKit"),
    ],
    targets: [
        .target(
            name: "VinOutlineKit",
            dependencies: [
				"MarkdownAttributedString",
				"VinXML",
				"VinCloudKit",
			]),
    ]
)
