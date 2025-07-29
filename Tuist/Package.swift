// swift-tools-version: 5.9
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    productTypes: ["Alamofire": .framework,
                   "Kingfisher": .framework,
                   "KakaoOpenSDK": .framework,
                   "Firebase": .framework,
                  ]
)
#endif

let package = Package(
    name: "SwypApp2nd",
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire", from: "5.0.0"),
        .package(
            url: "https://github.com/onevcat/Kingfisher.git",
            from: "7.0.0"
        ),
        .package(url: "https://github.com/kakao/kakao-ios-sdk", exact: "2.24.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.12.0"),
        .package(url: "https://github.com/ArtSabintsev/Siren.git", from: "5.5.0"),
    ]
)
