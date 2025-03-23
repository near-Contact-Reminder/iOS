import SwiftUI

// TODO: - 로그아웃 버튼 이동시 삭제.
import KakaoSDKUser
import AuthenticationServices

public struct HomeView: View {

    @EnvironmentObject var userSession: UserSession
    
    public var body: some View {
        VStack {
            Text("Home View")
            
            // MARK: - Test
            if userSession.user?.loginType == .kakao {
                // 카카오 로그아웃 버튼
                Button {
                    UserApi.shared.logout {(error) in
                        if let error = error {
                            print(error)
                        }
                        else {
                            print("kakao logout success.")
                            userSession.kakaoLogout()
                        }
                    }
                } label: {
                    Text("카카오 로그아웃")
                }
            } else {
                // apple 로그아웃 버튼
                Button {
                    userSession.appleLogout()
                } label: {
                    Text("애플 로그아웃")
                }
            }
        }
    }
}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(UserSession.shared)
    }
}
