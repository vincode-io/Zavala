// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Templeton",
	platforms: [.macOS(SupportedPlatform.MacOSVersion.v11), .iOS(SupportedPlatform.IOSVersion.v14)],
    products: [
        .library(
            name: "Templeton",
            targets: ["Templeton"]),
    ],
    dependencies: [
		.package(url: "https://github.com/Ranchero-Software/RSCore.git", .branch("main")),
		.package(url: "https://github.com/drmohundro/SWXMLHash.git", .upToNextMajor(from: "5.0.1")),
		.package(url: "https://github.com/vincode-io/MarkdownAttributedString.git", .branch("master")),
		.package(url: "https://github.com/vincode-io/VinXML.git", .branch("main")),
		.package(url: "https://github.com/apple/swift-collections.git", .upToNextMajor(from: "1.0.2")),
    ],
    targets: [
        .target(
            name: "Templeton",
            dependencies: [
				"RSCore",
				"SWXMLHash",
				"MarkdownAttributedString",
				"VinXML",
				.product(name: "OrderedCollections", package: "swift-collections")
			]),
        .testTarget(
            name: "TempletonTests",
            dependencies: ["Templeton"]),
    ]
)
