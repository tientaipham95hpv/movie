// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MovieApp",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "MovieApp",
            targets: ["MovieApp"]
        )
    ],
    targets: [
        .target(
            name: "MovieApp",
            path: "MovieApp"
        )
    ]
)
