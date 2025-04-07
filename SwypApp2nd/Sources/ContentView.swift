import SwiftUI
import KakaoSDKCommon
import KakaoSDKAuth

enum AppRoute: Hashable {
    case inbox
    case person(PersonEntity)
}

public struct ContentView: View {
    @StateObject private var userSession = UserSession.shared
    @StateObject private var loginViewModel = LoginViewModel()
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var notificationViewModel = NotificationManager.shared.notificationViewModel
    
    private let skipLoginForTesting: Bool = true
    @State private var path: [AppRoute] = []
    public init() {
        // Kakao SDK 초기화
//        KakaoSDK.initSDK(appKey: Bundle.main.infoDictionary?["KAKAO_APP_KEY"] as? String ?? "")
    }

    public var body: some View {
        NavigationStack(path: $path) {
            Group {
                if skipLoginForTesting || userSession.isLoggedIn {
                    // 테스트용
                    HomeView(homeViewModel: homeViewModel, path: $path)
                        .transition(.move(edge: .leading))
                } else {
                    // 실제 로그인 안 된 경우
                    LoginView(loginViewModel: loginViewModel)
                        .transition(.move(edge: .leading))
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .inbox:
                    NotificationInboxView(path: $path)
                case .person(let person):
                    ProfileDetailView(person: person)
                }
            }

        }
        .onAppear {
            userSession.tryAutoLogin()
        }
        .animation(.easeInOut(duration: 0.4), value: userSession.isLoggedIn)
        .environmentObject(userSession)
        .environmentObject(notificationViewModel)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

