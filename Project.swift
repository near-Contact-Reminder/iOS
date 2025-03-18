import ProjectDescription

let project = Project(
    name: "SwypApp2nd",
    options: .options(
        automaticSchemesOptions: .disabled,
        defaultKnownRegions: ["en", "ko"],
        developmentRegion: "ko",
        textSettings: 
                .textSettings(usesTabs: false, indentWidth: 4, tabWidth: 4)
    ),
    targets: [
        .target(
            name: "SwypApp2nd",
            destinations: .iOS,
            product: .app,
            bundleId: "io.tuist.SwypApp2nd",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: [
                "SwypApp2nd/Sources/**",
                "SwypApp2nd/Sources/Views/**",
                "SwypApp2nd/Sources/ViewModels/**",
                "SwypApp2nd/Sources/Models/**",
                "SwypApp2nd/Sources/Networks/**",
                "SwypApp2nd/Sources/Services/**",
                "SwypApp2nd/Sources/CommonComponents/**",
            ],
            resources: ["SwypApp2nd/Resources/**"],
            dependencies: [
                .external(name: "Alamofire"),
                .external(name: "Kingfisher")
            ],
            settings: .settings(base: [
                "RUN_EXECUTABLE_PATH": "$(BUILT_PRODUCTS_DIR)/SwypApp2nd.app"
            ])
        ),
        .target(
            name: "SwypApp2ndTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "io.tuist.SwypApp2ndTests",
            infoPlist: .default,
            sources: ["SwypApp2nd/Tests/**"],
            resources: [],
            dependencies: [.target(name: "SwypApp2nd")]
        ),
    ]
)
