// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftReactor",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "SwiftReactor",
            targets: ["SwiftReactor"]
        ),
        .library(
            name: "SwiftReactorUIKit",
            targets: ["SwiftReactorUIKit"]
        ),
        .library(
            name: "AsyncReactor",
            targets: ["AsyncReactor"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SwiftReactor",
            dependencies: [],
            path: "Sources/SwiftReactor"
        ),
        .target(
            name: "SwiftReactorUIKit",
            dependencies: ["SwiftReactor"],
            path: "Sources/SwiftReactorUIKit"
        ),
        .target(
            name: "AsyncReactor",
            dependencies: [],
            path: "Sources/AsyncReactor"
        ),
        .testTarget(
            name: "SwiftReactorTests",
            dependencies: ["SwiftReactor"]
        ),
        .testTarget(
            name: "SwiftReactorUIKitTests",
            dependencies: ["SwiftReactorUIKit"]
        ),
        .testTarget(
            name: "AsyncReactorTests",
            dependencies: ["AsyncReactor"]
        )
    ]
)
