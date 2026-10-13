// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "rho",
    platforms: [.macOS(.v13)],
    products: [.library(name: "KeymapperCore", targets: ["KeymapperCore"])],
    targets: [
        .target(name: "KeymapperCore"),
        .executableTarget(name: "CoreTests", dependencies: ["KeymapperCore"], path: "Tests/KeymapperCoreTests")
    ]
)
