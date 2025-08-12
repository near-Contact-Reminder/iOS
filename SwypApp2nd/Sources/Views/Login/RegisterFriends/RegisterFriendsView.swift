import SwiftUI

struct RegisterFriendView: View {
    @ObservedObject var viewModel: RegisterFriendsViewModel
    @State private var showContactPicker = false

    let proceed: () -> Void
    let skip: () -> Void
    
    private var contactListSection: some View {
        VStack(spacing: 12) {
            if !viewModel.phoneContacts.isEmpty {
                ForEach(viewModel.phoneContacts) { contact in
                    ContactRow(contact: contact) {
                        viewModel.removeContact(contact)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    
    var body: some View {
        Spacer()
            .frame(height: 12)
        
        VStack(alignment: .leading, spacing: 24) {
            // 헤더 텍스트
            VStack(alignment: .leading, spacing: 12) {
                
                HStack {
                    Text("챙길 사람 불러오기")
                        .modifier(Font.Pretendard.b1BoldStyle())
                        .foregroundColor(.black)
                    Spacer()
                    Text("1 / 2")
                        .modifier(Font.Pretendard.captionBoldStyle())
                        .foregroundColor(.gray02)
                }
                
                Spacer()
                    .frame( height: 20)

                Image("img_100_character_default")
                    .frame(height: 80)

                Text("가까워지고 싶은 사람\n10명까지 선택해주세요")
                    .modifier(Font.Pretendard.h1BoldStyle())

                Text("먼저, 더 가까워지고 싶은\n소중한 사람만 선택해주세요.")
                    .modifier(Font.Pretendard.b1MediumStyle())
                    .foregroundColor(.gray02)
            }
            .padding(.horizontal, 20)

            // 불러오기 카드 버튼, 가져온 연락처
            ScrollView {
                VStack(spacing: 12) {
                    // 연락처
                    VStack(spacing: 12) {
                        CardButton(
                            icon: Image("img_32_contact_square"),
                            title: "연락처에서 불러오기",
                            hasContacts: !viewModel.phoneContacts.isEmpty,
                            action: {
                                viewModel.requestContactsPermission { granted in
                                    if granted {
                                        showContactPicker = true
                                    } else {
                                        viewModel.activeAlert = .permissionDenied
                                    }
                                }
                                AnalyticsManager.shared.contactImportLogAnalytics()
                            }
                        )
                        .sheet(isPresented: $showContactPicker) {
                            ContactPickerView { contacts in
                                viewModel.handleSelectedContacts(contacts)
                            }
                        }
                        
                        if !viewModel.phoneContacts.isEmpty {
                            ForEach(viewModel.phoneContacts) { contact in
                                ContactRow(contact: contact) {
                                    viewModel.removeContact(contact)
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            Spacer()

            // 하단 버튼
            HStack(spacing: 12) {
                Button(action: skip) {
                    Text("나중에 하기")
                        .modifier(Font.Pretendard.b1BoldStyle())
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.black)
                        .frame(height: 52)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }

                Button(action: proceed) {
                    Text("다음")
                        .modifier(Font.Pretendard.b1BoldStyle())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(viewModel.canProceed ? Color.blue01 : Color.gray02)
                        .cornerRadius(12)
                }
                .disabled(!viewModel.canProceed)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .alert(item: $viewModel.activeAlert) { alert in
            switch alert {
            case .limitExceeded(let total):
                return Alert(
                    title: Text("⚠️ 제한 안내"),
                    message: Text("최대 10명까지만 등록할 수 있어요.\n(현재 \(total)명)"),
                    dismissButton: .default(Text("확인"))
                )
            case .phoneSelectionExceeded:
                return Alert(
                    title: Text("⚠️ 제한 안내"),
                    message: Text("연락처는 최대 10명까지만 선택할 수 있어요."),
                    dismissButton: .default(Text("확인"))
                )
            case .permissionDenied:
                return Alert(
                    title: Text("연락처 권한이 꺼져 있어요"),
                    message: Text("소중한 사람을 불러오기 위해\n설정에서 연락처 접근을 켜주세요."),
                    primaryButton: .default(Text("설정으로 이동")) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    },
                    secondaryButton: .cancel(Text("취소"))
                )
            }
        }
        .onAppear {
            AnalyticsManager.shared.trackRegisterFriendsViewLogAnalytics()
        }
    }
}

// MARK: - 카드 버튼 뷰 컴포넌트
struct CardButton: View {
    let icon: Image
    let title: String
    let hasContacts: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .cornerRadius(8)

                Text(title)
                    .modifier(Font.Pretendard.b2MediumStyle())
                    .foregroundColor(.black)

                Spacer()

                if hasContacts {
                    Text("다시 선택")
                        .modifier(Font.Pretendard.b2MediumStyle())
                        .foregroundColor(.blue01)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray02)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 8)
        }
    }
}

// MARK: - 가져온 연락처 Row
struct ContactRow: View {
    let contact: Friend
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(.img24Contact)
                .resizable()
                .frame(width: 24, height: 24)

            Text(contact.name)
                .modifier(Font.Pretendard.b2MediumStyle())
                .foregroundColor(.black)

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.bg02)
        .cornerRadius(12)
    }
}


#Preview {
    RegisterFriendView(
        viewModel: RegisterFriendsViewModel(),
        proceed: { print("다음 눌림") },
        skip: { print("나중에 하기 눌림") }
    )
}
