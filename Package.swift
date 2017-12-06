// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "Powwow-Service",
    targets: [],
    dependencies: [
	.Package(url: "https://github.com/PerfectlySoft/Perfect-HTTPServer.git", majorVersion: 2),
	.Package(url: "https://github.com/PerfectlySoft/Perfect-MySQL.git", majorVersion: 3)
    ]
)
