import SwiftUI

// TODO: - 로그아웃 버튼 이동시 삭제.
import KakaoSDKUser
import AuthenticationServices

public struct HomeView: View {

    @ObservedObject var homeViewModel: HomeViewModel
    @ObservedObject var notificationViewModel: NotificationViewModel

    @State private var showInbox = false
    @Binding var path:[AppRoute]

    @EnvironmentObject var userSession: UserSession
    
    
    public var body: some View {
            VStack {
                // MARK: - Test
                ForEach(notificationViewModel.reminders, id: \.self) { reminder in
                }
                
                Button(action: {
                    notificationViewModel.deleteAllReminders()
                }) {
                    Label("전체 삭제하기", systemImage: "trash")
                }
                    
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
                Spacer()
            }
            .navigationTitle("홈")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ZStack(alignment: .topTrailing) {
                        Button(action: {
                            path.append(.inbox)
                        }) {
                            Image(systemName: "bell")
                                .font(.title2)
                        }
                        
                        if notificationViewModel.badgeCount > 0 {
                            Text("\(notificationViewModel.badgeCount)")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(5)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 10, y: -10)
                        }
                    }
                }
            }
        }
    }


