import SwiftUI
import KakaoSDKCommon
import KakaoSDKAuth

public struct ContentView: View {
    @StateObject private var userSession = UserSession.shared
    
    public init() {
        // Kakao SDK 초기화
        KakaoSDK.initSDK(appKey: Bundle.main.infoDictionary?["KAKAO_APP_KEY"] as? String ?? "")
    }

    public var body: some View {
        Group {
            if userSession.isLoggedIn {
                HomeView()
            } else {
                LoginView()
            }
        }
        .environmentObject(userSession)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
