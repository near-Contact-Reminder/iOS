import SwiftUI
import KakaoSDKCommon
import KakaoSDKAuth

// TODO: - 연결후 파일로 분할
enum AppStep {
    case login
    case terms
    case registerFriends
    case setFrequency
    case home
}

// TODO: - AppRoute
enum AppRoute: Hashable {
    case inbox
    case person(PersonEntity)
}

public struct ContentView: View {
    @StateObject private var userSession = UserSession.shared
    @StateObject private var loginViewModel = LoginViewModel()
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var termsViewModel = TermsViewModel()
    @StateObject private var notificationViewModel = NotificationViewModel()
    @StateObject private var registerFriendsViewModel = RegisterFriendsViewModel()
    @StateObject private var contactFrequencyViewModel = ContactFrequencySettingsViewModel()
    
    private let skipLoginForTesting: Bool = true
    @State private var path: [AppRoute] = []
    
    public init() {
        // Kakao SDK 초기화
        KakaoSDK.initSDK(appKey: Bundle.main.infoDictionary?["KAKAO_APP_KEY"] as? String ?? "")
    }

    public var body: some View {
        Group {
            switch userSession.appStep {
            case .login, .terms:
                LoginView(loginViewModel: loginViewModel)
                
            case .registerFriends:
                RegisterFriendView(viewModel: registerFriendsViewModel, proceed: {
                    contactFrequencyViewModel.setPeople(from: registerFriendsViewModel.selectedContacts) // 선택된 연락처 전달
                    userSession.appStep = .setFrequency
                }, skip: {
                    userSession.appStep = .home
                })
                
            case .setFrequency:
                ContactFrequencySettingsView(viewModel: contactFrequencyViewModel, back: {
                    userSession.appStep = .registerFriends
                }, complete: {
                    // TODO: - BackEnd 서버에 친구 목록 전달해주는 API 호출 필요
                    userSession.appStep = .home
                })
                
            case .home:
                //                HomeView(homeViewModel: homeViewModel, notificationViewModel: notificationViewModel, path: )
                NavigationStack(path: $path) {
                    HomeView(homeViewModel: homeViewModel, notificationViewModel: notificationViewModel, path: $path)
                        .transition(.move(edge: .leading))
                        .navigationDestination(for: AppRoute.self) { route in
                            switch route {
                            case .inbox:
                                NotificationInboxView(path: $path)
                            case .person(let person):
                                ProfileDetailView(person: person)
                            }
                        }
                }
            }
        }
        .sheet(isPresented: Binding<Bool>(
            get: { userSession.appStep == .terms },
            set: { if !$0 { userSession.appStep = .registerFriends } }
        )) {
            TermsView(viewModel: termsViewModel) {
                DispatchQueue.main.async {
                    userSession.appStep = .registerFriends
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            userSession.tryAutoLogin()
        }
        .animation(.easeInOut(duration: 0.4), value: userSession.appStep)
        .environmentObject(userSession)
    }
}


//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
