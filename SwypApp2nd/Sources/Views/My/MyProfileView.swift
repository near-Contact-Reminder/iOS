import SwiftUI
import Combine

struct ServiceDetail: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let urlString: String
}

struct MyProfileView: View {
    @State private var showWithdrawalSheet = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                UserProfileSectionView()

                AccountSettingSectionView()

                ServiceInfoSectionView()
                
                WithdrawalButtonView {
                    showWithdrawalSheet = true
                }
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
    var body: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 100, height: 100)

            Text(UserSession.shared.user?.name ?? "김민지")
                .font(.title3)
                .fontWeight(.semibold)
        }
        .padding(.top, 40)
    }
}

struct AccountSettingSectionView: View {
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
                
                if let loginType = UserSession.shared.user?.loginType {
                    let (loginName, imageName): (String, String) = {
                        switch loginType {
                        case .kakao: return ("카카오톡", "image_32_kakao")
                        case .apple: return ("애플", "image_32_apple")
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
            }
            .padding()
            .background(Color(.systemGray6))

            NotificationSettingsView()
        }
    }
}

struct NotificationSettingsView: View {
    @StateObject private var viewModel = MyViewModel()
    @Environment(\.scenePhase) private var scenePhase

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

public struct ServiceInfoRowView: View {
    var title: String
    var isBold: Bool = false
    var showDetail: Bool = false
    var detailURLString: String? = nil
    var onDetailTappedClosure: ((String, String) -> Void)?
    
    public init(
            title: String,
            isBold: Bool = false,
            showDetail: Bool = false,
            detailURLString: String? = nil,
            onDetailTappedClosure: ((String, String) -> Void)? = nil
        ) {
            self.title = title
            self.showDetail = showDetail
            self.detailURLString = detailURLString
            self.onDetailTappedClosure = onDetailTappedClosure
        }
    
    public var body: some View {
        HStack {
            Text(title)
                .font(isBold ? .Pretendard.b1Bold() : .Pretendard.b1Medium())
            
            Spacer()
            
            if showDetail, let detailURLString = detailURLString {
                Button {
                    onDetailTappedClosure?(title, detailURLString)
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
        }
                .padding()
                .background(Color.white)
                .cornerRadius(8)
            
        }
    }

public struct ServiceInfoSectionView : View {
    
    @State private var selectedAgreement: ServiceDetail?
    
    public var body: some View {
        // TODO 터치시 안감?
        ServiceInfoRowView(
            title: "서비스 이용 약관",
            isBold: false,
            showDetail: true,
            detailURLString: "https://example.com/",
            onDetailTappedClosure: { title, url in
                self.selectedAgreement = ServiceDetail(title: title, urlString: url)
            })
        Divider()
            .background(Color.gray02)
            .padding(.horizontal, 24)
        ServiceInfoRowView(
            title: "개인정보 수집 및 이용 동의서",
            isBold: false,
            showDetail: true,
            detailURLString: "https://example.com/",
            onDetailTappedClosure: { title, url in
                self.selectedAgreement = ServiceDetail(title: title, urlString: url)
            })
        Divider()
            .background(Color.gray02)
            .padding(.horizontal, 24)
        ServiceInfoRowView(
            title: "개인정보 처리방침",
            isBold: false,
            showDetail: true,
            detailURLString: "https://example.com/",
            onDetailTappedClosure: { title, url in
                self.selectedAgreement = ServiceDetail(title: title, urlString: url)
            })
    }
}


struct WithdrawalButtonView: View {
    var onWithdrawTap: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Button(action: {
                // 로그아웃 처리
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



struct MyProfileView_Previews: PreviewProvider {
    static var previews: some View {
        MyProfileView()
    }
}
