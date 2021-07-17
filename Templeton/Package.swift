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
    ],
    targets: [
        .target(
            name: "Templeton",
            dependencies: [
				"RSCore",
				"SWXMLHash",
				"MarkdownAttributedString"
			],
			resources: [.copy("Localizable.strings")]),
        .testTarget(
            name: "TempletonTests",
            dependencies: ["Templeton"]),
    ]
)
