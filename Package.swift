// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftyReactor",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "SwiftyReactor",
            targets: ["SwiftyReactor"]),
        .library(
            name: "SwiftyReactorUIKit",
            targets: ["SwiftyReactorUIKit"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SwiftyReactor",
            dependencies: [],
            path: "Sources/SwiftyReactor"),
        .target(
            name: "SwiftyReactorUIKit",
            dependencies: ["SwiftyReactor"],
            path: "Sources/SwiftyReactorUIKit"),
        .testTarget(
            name: "SwiftyReactorTests",
            dependencies: ["SwiftyReactor"]),
        .testTarget(
            name: "SwiftyReactorUIKitTests",
            dependencies: ["SwiftyReactorUIKit"])
    ]
)
