// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "simai_flutter",
  platforms: [.iOS("13.0")],
  products: [
    .library(name: "simai-flutter", targets: ["simai_flutter"])
  ],
  targets: [
    .target(
      name: "simai_flutter",
      linkerSettings: [
        .linkedFramework("AVFoundation"),
        .linkedFramework("VideoToolbox"),
        .linkedFramework("Accelerate"),
        .linkedFramework("Photos"),
        .linkedFramework("UIKit"),
      ]
    )
  ]
)
