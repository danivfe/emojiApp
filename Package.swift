// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "Emojis",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Emojis",
            path: "Sources/Emojis",
            // emojis.json es copia dins l'.app amb scripts/build_app.sh
            exclude: ["Resources"]
        )
    ]
)
