// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AiRephrase",
    platforms: [
        .macOS(.v26)
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.2.1")
    ],
    targets: [
        .executableTarget(
            name: "AiRephrase",
            dependencies: ["KeyboardShortcuts"],
            path: "AiRephrase"
        )
    ]
)
