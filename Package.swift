// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "rho",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "PrivateKeymapper", targets: ["PrivateKeymapper"]),
               .executable(name: "rho", targets: ["RhoCLI"])],
    targets: [
        .target(name: "KeymapperCore"),
        .executableTarget(name: "PrivateKeymapper", dependencies: ["KeymapperCore"]),
        .executableTarget(name: "RhoCLI", dependencies: ["KeymapperCore"]),
        .executableTarget(name: "CoreTests", dependencies: ["KeymapperCore"], path: "Tests/KeymapperCoreTests")
    ]
)
