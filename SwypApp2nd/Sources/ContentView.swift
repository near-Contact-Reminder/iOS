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
    case my
    case person(PersonEntity)
    case personDetail(Friend)
}

enum ProfileDetailRoute {
    case edit
}

public struct ContentView: View {
    @StateObject private var userSession = UserSession.shared
    @StateObject private var loginViewModel = LoginViewModel()
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var termsViewModel = TermsViewModel()
    @StateObject private var notificationViewModel = NotificationViewModel()
    @StateObject private var registerFriendsViewModel = RegisterFriendsViewModel()
    @StateObject private var contactFrequencyViewModel = ContactFrequencySettingsViewModel()
    @StateObject private var myViewModel = MyViewModel()
    
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
                    print("🟢 [RegisterFriendsViewModel] \(registerFriendsViewModel.selectedContacts) 전달됨")
                    userSession.appStep = .setFrequency
                }, skip: {
                    userSession.appStep = .home
                })
                
            case .setFrequency:
                ContactFrequencySettingsView(viewModel: contactFrequencyViewModel, notificationViewModel: notificationViewModel, back: {
                    userSession.appStep = .registerFriends
                }, complete: { updatedPeoples in
                    DispatchQueue.main.async {
                        print("🟢 [ContactFrequencySettingsView] 전달받은 people: \(updatedPeoples.map { $0.name })")
//                        homeViewModel.peoples = updatedPeoples
                        UserSession.shared.user?.friends = updatedPeoples
                        userSession.appStep = .home
                    }
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
//                            case .person(let person):
//                                ProfileDetailView(person: person)
                            case .person(_):
                                NotificationInboxView(path: $path)
                            case .my:
                                MyProfileView(path: $path)
                            case .personDetail(let friend):
                                let profileDetailViewModel = ProfileDetailViewModel(people: friend)
                                ProfileDetailView(viewModel: profileDetailViewModel, path: $path)
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
