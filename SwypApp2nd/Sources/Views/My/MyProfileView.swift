import SwiftUI

struct MyProfileView: View {
    @State private var showWithdrawalSheet = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                UserProfileSectionView()

                AccountSettingSectionView()

                ServiceInfoSectionView()

                Spacer()

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

            Text("김민지")
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
                HStack(spacing: 5) {
                    Text("카카오톡")
                        .foregroundColor(.gray)
                    Image("kakao_icon") // TODO: 이미지 추가
                        .resizable()
                        .frame(width: 20, height: 20)
                }
            }
            .padding()
            .background(Color(.systemGray6))

            NotificationSettingsView()
        }
    }
}

struct NotificationSettingsView: View {
    @AppStorage("isNotificationOn") private var isNotificationOn: Bool = false
    @State private var didLoadStatus = false
    @State private var showSettingsAlert = false

    var body: some View {
        Toggle("알림설정", isOn: $isNotificationOn)
            .onChange(of: isNotificationOn) { newValue in
                guard didLoadStatus else { return }

                if newValue {
                    UNUserNotificationCenter.current().getNotificationSettings { settings in
                        DispatchQueue.main.async {
                            switch settings.authorizationStatus {
                            case .notDetermined:
                                // 아직 요청 안했으면 요청 시도
                                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                                    DispatchQueue.main.async {
                                        isNotificationOn = granted
                                    }
                                }
                            case .denied:
                                // 권한 거부된 상태 → Alert로 설정 이동 유도
                                isNotificationOn = false
                                showSettingsAlert = true
                            case .authorized, .provisional:
                                // 이미 허용됨 → 아무 일 없음
                                break
                            default:
                                break
                            }
                        }
                    }
                } else {
                    NotificationManager.shared.disableNotifications()
                }
            }
            .onAppear {
                NotificationManager.shared.fetchNotificationStatus { enabled in
                    isNotificationOn = enabled
                    didLoadStatus = true
                }
            }
            .alert("휴대폰 알림이 꺼져 있어요.", isPresented: $showSettingsAlert) {
                
                Button("설정하러 가기") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("취소", role: .cancel) { }
                
            } message: {
                Text("알림 설정을 켜야 챙김 알림을 받을 수 있어요.")
            }
            .padding()
            .background(Color(.systemGray6))
    }
}

struct ServiceInfoSectionView: View {
    var body: some View {
        VStack(spacing: 1) {
            Text("서비스 정보")
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 16)

            NavigationLink(destination: Text("서비스 이용 약관")) {
                serviceRow(title: "서비스 이용 약관")
            }
            NavigationLink(destination: Text("개인정보 수집 및 이용 동의서")) {
                serviceRow(title: "개인정보 수집 및 이용 동의서")
            }
            NavigationLink(destination: Text("개인정보 처리방침")) {
                serviceRow(title: "개인정보 처리방침")
            }
        }
        .padding(.top, 10)
    }

    private func serviceRow(title: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemGray6))
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
