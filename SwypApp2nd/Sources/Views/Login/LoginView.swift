import SwiftUI
import AuthenticationServices

public struct LoginView: View {
    @ObservedObject var loginViewModel: LoginViewModel
    @EnvironmentObject var userSession: UserSession

    public var body: some View {
        VStack(spacing: 16) {
                    
            // 카카오 로그인
            Button(action: {
                loginViewModel.loginWithKakao()
            }) {
                Image("kakao_login_large_wide")
                    .resizable()
                    .scaledToFit()
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
                    
            // 애플 로그인
            SignInWithAppleButton(
                onRequest: loginViewModel.handleAppleRequest,
                onCompletion: loginViewModel.handleAppleCompletion
            )
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .signInWithAppleButtonStyle(.black)
        }
        .padding()
    }
}
