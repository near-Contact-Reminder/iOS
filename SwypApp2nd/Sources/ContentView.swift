import SwiftUI
import KakaoSDKCommon
import KakaoSDKAuth

public struct ContentView: View {
    @StateObject private var userSession = UserSession.shared
    @StateObject private var loginViewModel = LoginViewModel()
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var termsViewModel = TermsViewModel()
    
    public init() {
        // Kakao SDK 초기화
        KakaoSDK.initSDK(appKey: Bundle.main.infoDictionary?["KAKAO_APP_KEY"] as? String ?? "")
    }

    public var body: some View {
        Group {
            if userSession.isLoggedIn {
                HomeView(homeViewModel: homeViewModel)
                    .transition(.move(edge: .leading))
                    
            } else {
                LoginView(loginViewModel: loginViewModel)
                    .transition(.move(edge: .leading))
            }
        }
        .sheet(isPresented: $userSession.shouldShowTerms) {
            TermsView(viewModel: termsViewModel) {
                userSession.shouldShowTerms = false
            }
            .interactiveDismissDisabled()
            .presentationDetents([.medium])
            .presentationDragIndicator(.hidden)
            
        }
        .onAppear {
            userSession.tryAutoLogin()
        }
        .animation(.easeInOut(duration: 0.4), value: userSession.isLoggedIn)
        .environmentObject(userSession)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
