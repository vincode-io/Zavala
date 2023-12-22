// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "VinOutlineKit",
	platforms: [.macOS(SupportedPlatform.MacOSVersion.v11), .iOS(SupportedPlatform.IOSVersion.v14)],
    products: [
        .library(
            name: "VinOutlineKit",
            targets: ["VinOutlineKit"]),
    ],
    dependencies: [
		.package(url: "https://github.com/vincode-io/MarkdownAttributedString.git", .branch("master")),
		.package(url: "https://github.com/vincode-io/VinXML.git", .branch("main")),
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
