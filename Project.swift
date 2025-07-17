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
            destinations: [.iPhone],
            product: .app,
            bundleId: "io.tuist.SwypApp2nd",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleDisplayName": "near - 연락 알리미",
                    "UIDeviceFamily": [1],
                    "UISupportedInterfaceOrientations": [
                        "UIInterfaceOrientationPortrait"
                    ],
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
                    "FirebaseAutomaticScreenReportingEnabled": false,
//                    "LSApplicationQueriesSchemes": [
//                        "kakaokompassauth" // 앱으로 로그인
//                    ],
                    "CFBundleIconName": "AppIcon",
                    "UIUserInterfaceStyle": "Light",
                    "CFBundleShortVersionString": "$(MARKETING_VERSION)",
                    "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
                    "NSContactsUsageDescription": "내 사람들을 등록하려면 연락처 접근 권한이 필요합니다.\n선택한 연락처만 사용되며, 저장되지 않은 정보는 수집되지 않습니다.",
                    "UIBackgroundModes": [
                        "remote-notification"
                    ],
                    "KAKAO_APP_KEY": "$(KAKAO_APP_KEY)",
                    "DEV_BASE_URL": "$(DEV_BASE_URL)",
                    "RELEASE_BASE_URL": "$(RELEASE_BASE_URL)",
                    "SERVICE_AGREED_TERMS_URL": "$(SERVICE_AGREED_TERMS_URL)",
                    "PERSONAL_INFO_TERMS_URL": "$(PERSONAL_INFO_TERMS_URL)",
                    "PRIVACY_POLICY_TERMS_URL": "$(PRIVACY_POLICY_TERMS_URL)"
                ]
            ),
            sources: [
                "SwypApp2nd/Sources/**"
            ],
            resources: ["SwypApp2nd/Resources/**",
                        "Tuist/GoogleService-Info.plist"
//                       "SwypApp2nd/Resources/External/KakaoSDKFriendResources.bundle"
                       ],
            entitlements: "Tuist/SignInWithApple.entitlements",
            dependencies: [
                .external(name: "Alamofire"),
                .external(name: "Kingfisher"),
                .external(name: "KakaoSDKCommon"),
                .external(name: "KakaoSDKTemplate"),
                .external(name: "KakaoSDKAuth"),
                .external(name: "KakaoSDKUser"),
                .external(name: "KakaoSDKTalk"),
                .external(name: "KakaoSDKFriend"),
                .external(name: "FirebaseMessaging"),
                .external(name: "FirebaseAnalytics")

            ],
            settings: .settings(base: [
                "RUN_EXECUTABLE_PATH": "$(BUILT_PRODUCTS_DIR)/SwypApp2nd.app",
                "MARKETING_VERSION": "1.0.4",
                "CURRENT_PROJECT_VERSION": "16",
                "OTHER_LDFLAGS": "$(inherited) -ObjC"
            ])
        ),
        .target(
            name: "SwypApp2ndTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "io.tuist.SwypApp2ndTests",
            infoPlist: .default,
            sources: ["SwypApp2nd/Tests/**"],
            resources: [],
            dependencies: [.target(name: "SwypApp2nd")]
        ),
    ]
)
