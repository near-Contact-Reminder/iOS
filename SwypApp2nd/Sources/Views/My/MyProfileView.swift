import SwiftUI
import Kingfisher
import Combine
import WebKit

struct ServiceDetail: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let urlString: String
}

struct MyProfileView: View {
    @Binding var path: [AppRoute]
    @State private var showWithdrawalSheet = false
    
    @StateObject var myViewModel =  MyViewModel()
    @StateObject var termsViewModel = TermsViewModel()
    var user = UserSession.shared.user!
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                UserProfileSectionView(name: user.name, profilePic: user.profileImageURL)
                AccountSettingSectionView(loginType: user.loginType)
                NotificationSettingsView(viewModel: myViewModel)
                SimpleTermsView(termsViewModel: termsViewModel)
                WithdrawalButtonView (
                    loginType: user.loginType,
                    onWithdrawTap: {
                        showWithdrawalSheet = true
                    },
                    path: $path
                )
            }
            .fullScreenCover(isPresented: $showWithdrawalSheet) {
                WithdrawalView()
            }
            .padding(.horizontal)
            .navigationBarTitle("MY", displayMode: .inline)
        }
    }
}

struct UserProfileSectionView: View {
    var name: String
    var profilePic: String?
    
    var body: some View {
        VStack(spacing: 10) {
            if let urlString = profilePic, let url = URL(string: urlString) {
                KFImage(url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 100)
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
            }
            
            Text(name)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .padding(.top, 40)
    }
}

struct AccountSettingSectionView: View {
    var loginType: LoginType
    
    var body: some View {
        VStack(spacing: 1) {
            Text("일반")
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.top, .bottom], 16)

            HStack {
                Text("연결계정")
                Spacer()
                let (loginName, imageName): (String, String) = {
                    switch loginType {
                    case .kakao: return ("카카오톡", "img_32_kakao")
                    case .apple: return ("애플", "img_32_apple")
                    }
                }()
                HStack(spacing: 5) {
                    Text(loginName)
                        .foregroundColor(.gray)

                    Image(imageName)
                        .resizable()
                        .frame(width: 20, height: 20)
                }
            }
            .padding()
            .background(Color(.systemGray6))
        }
    }
}

struct NotificationSettingsView: View {
    @ObservedObject var viewModel: MyViewModel
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        Toggle("알림설정", isOn: $viewModel.isNotificationOn)
            .padding()
            .background(Color(.systemGray6))
            .onAppear {
                viewModel.loadInitialState()
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    viewModel.loadInitialState()
                }
            }
            .alert("휴대폰 알림이 꺼져 있어요.", isPresented: $viewModel.showSettingsAlert) {
            Button("설정하러 가기") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("취소", role: .cancel) { viewModel.showSettingsAlert = false }
        } message: {
            Text("알림 설정을 켜야 \n챙김 알림을 받을 수 있어요.")
        }
        .padding()
        .background(Color(.systemGray6))
        }
    }

struct SimpleTermsView: View {
    @ObservedObject var termsViewModel: TermsViewModel
    @State private var selectedAgreement: AgreementDetail?

    var terms: [AgreementDetail] {
        [
            AgreementDetail(title: "서비스 이용 약관", urlString: termsViewModel.serviceAgreedTermsURL),
            AgreementDetail(title: "개인정보 수집 및 이용 동의서", urlString: termsViewModel.personalInfoTermsURL),
            AgreementDetail(title: "개인정보 처리방침", urlString: termsViewModel.privacyPolicyTermsURL)
        ]
    }

    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("서비스 약관 안내")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 40)
                .padding(.horizontal)

            ForEach(terms) { term in
                Button {
                    selectedAgreement = term
                } label: {
                    HStack {
                        Text(term.title)
                            .font(.body)
                            .foregroundColor(.black)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        .background(Color(.systemGroupedBackground))
        .fullScreenCover(item: $selectedAgreement) { agreement in
            NavigationStack {
                TermsDetailView(
                    title: agreement.title,
                    urlString: agreement.urlString
                )
                .presentationDetents([.large])
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Text(agreement.title)
                            .font(.headline)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            selectedAgreement = nil
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.black)
                        }
                    }
                }
            }
        }
    }
}


struct WithdrawalButtonView: View {
    var loginType: LoginType
    var onWithdrawTap: () -> Void
    @Binding var path: [AppRoute]
    
    var body: some View {
        VStack(spacing: 10) {
            Button(action: {
                if loginType == .kakao {
                    UserSession.shared.kakaoLogout{ success in
                        if success {
                            path.removeLast()
                            }
                    }
                }
                 else {
                     UserSession.shared.appleLogout{ success in
                         if success {
                             path.removeLast()
                             }
                     }
                }
            }) {
                Text("로그아웃")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 1)
                    )
            }
            .padding(.horizontal)

            Button(action: {
                onWithdrawTap()
            }) {
                Text("탈퇴하기")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
            }
        }
    }
}


//struct MyProfileView_Previews: PreviewProvider {
//    static var previews: some View {
//        MyProfileView()
//    }
//}
