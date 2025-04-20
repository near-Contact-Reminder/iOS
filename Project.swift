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
    settings: .settings(
        base: [:],
        configurations: [
            .debug(name: "Debug", xcconfig: "Tuist/Config/Config.xcconfig"),
            .release(
                name: "Release",
                xcconfig: "Tuist/Config/Config.xcconfig"
            ),
        ]
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
                    "UILaunchStoryboardName": "LaunchScreen",
                    "UIAppFonts": [
                        "Pretendard-Black.otf",
                        "Pretendard-Bold.otf",
                        "Pretendard-ExtraBold.otf",
                        "Pretendard-ExtraLight.otf",
                        "Pretendard-Light.otf",
                        "Pretendard-Medium.otf",
                        "Pretendard-Regular.otf",
                        "Pretendard-SemiBold.otf",
                        "Pretendard-Thin.otf",
                    ],
//                    "LSApplicationQueriesSchemes": [
//                        "kakaokompassauth" // 앱으로 로그인
//                    ],
                    "CFBundleIconName": "AppIcon",
                    "UIUserInterfaceStyle": "Light",
                    "CFBundleShortVersionString": "$(MARKETING_VERSION)",
                    "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
                    "NSContactsUsageDescription": "연락처에서 챙길 사람을 가져오려면\n 기기 설정에서 연락처를 허용해주세요.",
                    "KAKAO_APP_KEY": "$(KAKAO_APP_KEY)",
                    "DEV_BASE_URL": "$(DEV_BASE_URL)",
                    "SERVICE_AGREED_TERMS_URL": "$(SERVICE_AGREED_TERMS_URL)",
                    "PERSONAL_INFO_TERMS_URL": "$(PERSONAL_INFO_TERMS_URL)",
                    "PRIVACY_POLICY_TERMS_URL": "$(PRIVACY_POLICY_TERMS_URL)"
                ]
            ),
            sources: [
                "SwypApp2nd/Sources/**"
            ],
            resources: ["SwypApp2nd/Resources/**",
                       "SwypApp2nd/Resources/External/KakaoSDKFriendResources.bundle"
                       ],
            entitlements: "Tuist/SignInWithApple.entitlements",
            dependencies: [
                .external(name: "Alamofire"),
                .external(name: "Kingfisher"),
                .external(name: "KakaoSDKCommon"),
                .external(name: "KakaoSDKAuth"),
                .external(name: "KakaoSDKUser"),
                .external(name: "KakaoSDKFriend"),
                .external(name: "KakaoSDKTalk")
            ],
            settings: .settings(base: [
                "RUN_EXECUTABLE_PATH": "$(BUILT_PRODUCTS_DIR)/SwypApp2nd.app",
                "MARKETING_VERSION": "0.1.3",
                "CURRENT_PROJECT_VERSION": "4"
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
