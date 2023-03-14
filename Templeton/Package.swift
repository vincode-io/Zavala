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
		.package(url: "https://github.com/vincode-io/RSCore.git", .branch("cloudkit-rewrite")),
		.package(url: "https://github.com/drmohundro/SWXMLHash.git", .upToNextMajor(from: "5.0.1")),
		.package(url: "https://github.com/vincode-io/MarkdownAttributedString.git", .branch("master")),
		.package(url: "https://github.com/apple/swift-collections.git", .upToNextMajor(from: "1.0.2")),
    ],
    targets: [
        .target(
            name: "Templeton",
            dependencies: [
				"RSCore",
				"SWXMLHash",
				"MarkdownAttributedString",
				.product(name: "OrderedCollections", package: "swift-collections")
			],
			resources: [.copy("Localizable.strings")]),
        .testTarget(
            name: "TempletonTests",
            dependencies: ["Templeton"]),
    ]
)
