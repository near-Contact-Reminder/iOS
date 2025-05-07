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
    var user: User? {
        UserSession.shared.user
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let user = UserSession.shared.user {
                    NavigationView {
                        VStack(spacing: 20) {
                            UserProfileSectionView(
                                name: user.name,
                                profilePic: user.profileImageURL
                            )
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
                    }
                    .padding(.horizontal, 12)
                } else {
                    ProgressView()
                        .onAppear {
                            DispatchQueue.main.async {
                                if path.last == .my { 
                                    path.removeLast()
                                }
                            }
                        }
                }
                
            }
            .fullScreenCover(isPresented: $showWithdrawalSheet) {
                WithdrawalView(path: $path)
            }
        }
        .padding(.horizontal, 12)
    }
}

struct UserProfileSectionView: View {
    var name: String
    var profilePic: String?
    
    var body: some View {
        VStack(spacing: 16) {
            if let urlString = profilePic, let url = URL(string: urlString) {
                KFImage(url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
            } else {
                Image("_img_80_user1")
                    .frame(width: 80, height: 80)
            }
            Text(name)
                .font(Font.Pretendard.b1Bold())
        }
        .padding(.top,20)
    }
}

struct AccountSettingSectionView: View {
    var loginType: LoginType
    
    var body: some View {
        VStack(spacing: 1) {
            VStack(alignment: .leading, spacing: 24) {
                Text("일반")
                    .font(Font.Pretendard.b1Bold())
                    .fontWeight(.bold)
                    .padding(.top, 42)
                    .padding(.horizontal)
                
                HStack {
                    Text("연결계정")
                        .font(Font.Pretendard.b1Medium())
                        .foregroundColor(.black)
                    Spacer()
                    let (loginName, imageName): (String, String) = {
                        switch loginType {
                        case .kakao: return ("카카오", "img_32_kakao")
                        case .apple: return ("애플", "img_32_apple")
                        }
                    }()
                    
                    HStack(spacing: 5) {
                        Text(loginName)
                            .foregroundColor(.gray)
                        Image(imageName)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct NotificationSettingsView: View {
    @ObservedObject var viewModel: MyViewModel
    var body: some View {
        Toggle("알림설정", isOn: $viewModel.isNotificationOn)
            .padding(.horizontal)
            .font(Font.Pretendard.b1Medium())
            .tint(Color.blue02)
            .onAppear {
                viewModel.loadInitialState()
            }
            .onChange(of: viewModel.isNotificationOn) {newValue in
                if newValue {
                        viewModel.handleToggleOn()
                } else {
                    viewModel.turnOffNotifications()
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
        VStack(alignment: .leading, spacing: 14) {
            Text("서비스 정보")
                .font(Font.Pretendard.b1Bold())
                .fontWeight(.bold)
                .padding(.top, 42)
                .padding(.bottom, 14)
                .padding(.horizontal)

        ForEach(Array(terms.enumerated()), id: \.1.id) { index, term in
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
                            .frame(width: 24, height: 24)
                    }
                }
                if index < terms.count - 1 {
                    Divider()
                        .background(Color.gray02)
                }
            }
            .padding(.horizontal)
        }
        
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
                            DispatchQueue.main.async {
                                path.removeLast()
                            }
                        }
                    }
                }
                else {
                    UserSession.shared.appleLogout{ success in
                        if success {
                            DispatchQueue.main.async {
                                path.removeLast()
                            }
                        }
                    }
                }
            }) {
                Text("로그아웃")
                    .font(Font.Pretendard.b1Bold())
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray02, lineWidth: 1)
                    )
            }
            .padding(.horizontal)
            .padding(.top, 42)
            
            Button(action: {
                onWithdrawTap()
            }) {
                Text("탈퇴하기")
                    .font(Font.Pretendard.b2Medium())
                    .underline()
                    .lineSpacing(4)
                    .kerning(-0.25) // TODO
                    .foregroundColor(Color.gray01)
                    .padding(.bottom, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
            .padding(.top, 18)
        }
    }
}

struct MyProfileView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            previewForDevice("iPhone 13 mini")
            previewForDevice("iPhone 16")
            previewForDevice("iPhone 16 Pro")
            previewForDevice("iPhone 16 Pro Max")
        }
    }

    static func previewForDevice(_ deviceName: String) -> some View {

        let fakeFriends = [
            Friend(
                id: UUID(), name: "정종원1", image: nil, imageURL: nil,
                source: .kakao, frequency: CheckInFrequency.none, remindCategory: .message,
                nextContactAt: Date(), lastContactAt: Date().addingTimeInterval(-86400),
                checkRate: 20, position: 0
            )
        ]

        UserSession.shared.user = User(
            id: "preview", name: "프리뷰",
            friends: fakeFriends,
            loginType: .kakao,
            serverAccessToken: "token",
            serverRefreshToken: "refresh"
        )

        return MyProfileWrapper()
            .previewDevice(PreviewDevice(rawValue: deviceName))
            .previewDisplayName(deviceName)
    }


    struct MyProfileWrapper: View {
        @State var path: [AppRoute] = [.my]

        var body: some View {
            MyProfileView(path: $path)
        }
    
    }
}
