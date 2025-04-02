import AuthenticationServices
import SwiftUI

public struct LoginView: View {
    @ObservedObject var loginViewModel: LoginViewModel
    @StateObject private var termsViewModel = TermsViewModel()
    @EnvironmentObject var userSession: UserSession
    
    public var body: some View {
        VStack(spacing: 44) {

            Spacer()
                .frame(height: 14)

            VStack(spacing: 12) {
                Text("Near")
                    .font(.system(size: 36, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("소중한 사람들과\n더 가까워지는 스마트 리마인더")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 24)

            Spacer()

            Circle()
                .fill(Color(UIColor.systemGray5))
                .frame(width: 200, height: 200)

            Spacer()

            VStack(alignment: .center, spacing: 12) {
                // 카카오 로그인
                Button(action: {
                    loginViewModel.loginWithKakao()
                }) {
                    HStack(spacing: 6) {
                        Image("kakao_symbol_large")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 14)

                        Text("카카오로 시작하기")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                    }
                    .frame(height: 44)
                    .frame(maxWidth: .infinity)
                    .background(Color.kakaoBackgroundColor)
                    .cornerRadius(8)
                }

                // 애플 로그인
                SignInWithAppleButton(
                    onRequest: loginViewModel.handleAppleRequest,
                    onCompletion: loginViewModel.handleAppleCompletion
                )
                .frame(height: 44)
                .frame(maxWidth: .infinity)
                .signInWithAppleButtonStyle(.black)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .sheet(isPresented: Binding<Bool>(
            get: { userSession.shouldShowTerms },
            set: { newValue in userSession.shouldShowTerms = newValue }
        )) {
            TermsView(viewModel: termsViewModel) {
                DispatchQueue.main.async {
                    userSession.shouldShowTerms = false
                    userSession.isLoggedIn = true
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}
#Preview {
    LoginView(loginViewModel: LoginViewModel())
        .environmentObject(UserSession())
}
