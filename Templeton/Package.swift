// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Templeton",
    products: [
        .library(
            name: "Templeton",
            targets: ["Templeton"]),
    ],
    dependencies: [
		.package(url: "https://github.com/Ranchero-Software/RSCore.git", .upToNextMajor(from: "1.0.0-beta1")),
    ],
    targets: [
        .target(
            name: "Templeton",
            dependencies: [
				"RSCore",
			]),
        .testTarget(
            name: "TempletonTests",
            dependencies: ["Templeton"]),
    ]
)
