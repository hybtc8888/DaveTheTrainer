// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DaveDiverTrainer",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "DaveTheTrainer", targets: ["DaveTheTrainer"]),
        .library(name: "TrainerCore", targets: ["TrainerCore"])
    ],
    targets: [
        .target(
            name: "MachMemory",
            path: "Sources/MachMemory",
            publicHeadersPath: "include"
        ),
        .target(
            name: "TrainerCore",
            dependencies: ["MachMemory"],
            path: "Sources/TrainerCore"
        ),
        .executableTarget(
            name: "DaveTheTrainer",
            dependencies: ["TrainerCore"],
            path: "Sources/DaveTrainerApp"
        ),
        .testTarget(
            name: "TrainerCoreTests",
            dependencies: ["TrainerCore", "MachMemory"],
            path: "Tests/TrainerCoreTests"
        ),
        .testTarget(
            name: "DaveTrainerAppTests",
            dependencies: ["DaveTheTrainer"],
            path: "Tests/DaveTrainerAppTests"
        )
    ]
)
