import SwiftUI

struct ProfileDetailView: View {
    @ObservedObject var viewModel: ProfileDetailViewModel
    @ObservedObject var notificationViewModel: NotificationViewModel
    @Binding var path: [AppRoute]
    @State private var selectedTab: Tab = .profile
    @State private var showActionSheet = false
    @State private var isEditing = false
    @State private var showToast = false
    @State private var toastTask: DispatchWorkItem?

    /// 토스트를 일정 시간 뒤 사라지도록 묶어둔 헬퍼
    private func presentToastTemporarily() {
        showToast = true
        toastTask?.cancel()

        let task = DispatchWorkItem {
            withAnimation { showToast = false }
        }
        toastTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3, execute: task)
    }
    
    enum Tab {
        case profile, records
    }

    var body: some View {
        
        ZStack {
            if showToast {
                CareToastView()
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(1)
            }
            VStack(alignment: .leading, spacing: 28) {
                ProfileHeader(people: viewModel.people, checkInRecords: viewModel.checkInRecords, onDelete: {
                    viewModel.deleteFriend(friendId: viewModel.people.id) {
                        DispatchQueue.main.async {
                            path.removeAll()
                        }
                    }
                }).padding(.top, 26)
                ActionButtonRow(people: viewModel.people)
                ZStack {
                    ProfileTabBar(selected: $selectedTab)
                    Rectangle()
                        .fill(Color.gray03)
                        .frame(height: 1)
                        .offset(x: 0, y: 15)
                }
                
                ZStack {
                    ProfileInfoSection(people: viewModel.people)
                        .padding(.top, -16)
                        .opacity(selectedTab == .profile ? 1 : 0)
                    HistorySection(records: viewModel.checkInRecords)
                        .opacity(selectedTab == .records ? 1 : 0)
                }
                ConfirmButton(
                    title: viewModel.canCheckInToday ? "챙김 기록하기" : "챙김 기록 완료",
                    isEnabled: viewModel.canCheckInToday
                ) {
                    viewModel.checkFriend() {
                        presentToastTemporarily()
                        viewModel.fetchFriendRecords(friendId: viewModel.people.id)
                    }
                    AnalyticsManager.shared.dailyCheckButtonLogAnalytics()
                }
                .padding(.bottom, 20)
            }
        }
        .padding(.horizontal, 24)
        .navigationBarBackButtonHidden()
        .onAppear {
            viewModel.fetchFriendDetail(friendId: viewModel.people.id)
            viewModel.fetchFriendRecords(friendId: viewModel.people.id)
            
            AnalyticsManager.shared.trackProfileDetailViewLogAnalytics()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading)  {
                Button(action: {
                    path.removeLast()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("프로필 상세")
                    }
                    .foregroundColor(.black)
                    .font(Font.Pretendard.b1Bold())
                }
                .padding(.leading, 12)
            }
            
            
            ToolbarItem(placement: .topBarTrailing)  {
                Button(action: {
                    showActionSheet = true
                }) {
                    Image(systemName: "ellipsis")
                        .resizable()
                        .font(Font.Pretendard.b1Medium())
                        .rotationEffect(.degrees(90))
                        .foregroundColor(.black)
                }
                .padding(.trailing, 12)
            }
            
        }
        .confirmationDialog("옵션", isPresented: $showActionSheet, titleVisibility: .visible) {
                    Button("수정", role: .none) {
                        isEditing = true
                    }
                    Button("삭제", role: .destructive) {
                        viewModel.deleteFriend(friendId: viewModel.people.id) {
//                            print("삭제 버튼 클릭 됨")
//                            print("❌ 리마인드 삭제")
                            notificationViewModel.deleteRemindersEternally(person: viewModel.people)
//                            print("❌ 리마인드 삭제")
                            DispatchQueue.main.async {
                                path.removeAll()
                            }
                        }
                    }
                    Button("취소", role: .cancel) {}
                }
        .fullScreenCover(isPresented: $isEditing) {
            NavigationStack {
                let profileEditViewModel = ProfileEditViewModel(person: viewModel.people)
                ProfileEditView(
                    profileEditViewModel: profileEditViewModel) {
                        viewModel.fetchFriendDetail(friendId: viewModel.people.id)
                        viewModel.people = profileEditViewModel.person
                        isEditing = false
                    }
            }
        }
    }
}

struct HistorySection: View {
    let records: [CheckInRecord]
    
    var filteredRecords: [(offset: Int, element: CheckInRecord)] {
        Array(
            records
                .filter { $0.isChecked }
                .sorted(by: { $0.createdAt > $1.createdAt })
                .enumerated()
        )
    }
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
      
        VStack(alignment: .leading, spacing: 16) {
            Text("챙김 기록")
                .modifier(Font.Pretendard.b2BoldStyle())
                .foregroundColor(.black)
            ScrollView {
                if records.isEmpty {
                    VStack {
                        Spacer()
                        Image("img_100_character_empty")
//                        Spacer()
                        Text("챙긴 기록이 없어요.\n오늘 챙겨볼까요?")
                            .modifier(Font.Pretendard.b2MediumStyle())
                            .foregroundColor(Color.gray01)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(filteredRecords, id: \.element.id) { index, record in
                            let totalRecordCount = filteredRecords.count
                            VStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 44, style: .continuous)
                                        .fill(Color.white)
                                        .frame(width: 98, height: 98)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 44, style: .continuous)
                                                .stroke(Color.gray03, lineWidth: 1)
                                        )
                                    
                                    VStack(spacing: 4) {
                                        Image("img_100_character_success")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 40, height: 40)
                                                                           
                                        Text("\(totalRecordCount - index)번째 챙김")
                                            .modifier(Font.Pretendard.b2MediumStyle())
                                            .foregroundColor(.blue01)
                                    }
                                }
                                Text(record.createdAt.formattedYYMMDDWithDot())
                                    .modifier(Font.Pretendard.b2MediumStyle())
                                    .foregroundColor(.gray01)
                            }
                            
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

private struct ProfileHeader: View {
    let people: Friend
    let checkInRecords: [CheckInRecord]
    let onDelete: () -> Void
    
    var emojiImageName: String {
        guard let rate = people.checkRate else {
            return "icon_visual_24_emoji_0"
        }
        switch rate {
        case 0...30: return "icon_visual_24_emoji_0"
        case 31...60: return "icon_visual_24_emoji_50"
        default: return "icon_visual_24_emoji_100"
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .topTrailing) {
                if let image = people.image {
                    Image(uiImage: image)
                        .resizable()
                        .clipShape(Circle())
                        .frame(width: 80, height: 80)
                } else {
                    Image("_img_80_user1")
                        .resizable()
                        .frame(width: 80, height: 80)
                }
                
                Image(emojiImageName)
                    .frame(width: 24, height: 24)
                    .offset(x: 0, y: -5)
            }

            VStack(alignment: .leading, spacing: 8) {
                
                Text(people.name)
                    .frame(height: 22)
                    .modifier(Font.Pretendard.h2BoldStyle())
                    .multilineTextAlignment(.center)
                
                //MM월dd일 더 가까워졌어요
                if let latestRecordDate = checkInRecords.sorted(by: { $0.createdAt > $1.createdAt }).first?.createdAt {
                    Text("\(latestRecordDate.formattedYYYYMMDDMoreCloser())")
                        .modifier(Font.Pretendard.b2MediumStyle())
                        .foregroundColor(Color.blue01)
                } else {
                    Text("-")
                        .modifier(Font.Pretendard.b2MediumStyle())
                        .foregroundColor(Color.blue01)
                }
            }
        }
        
    }
}
private struct ActionButtonRow: View {
    
    var people: Friend
    // TODO: - showMessageAlert, selectedPhone, selectedMessage, selectedMessageComment 추후 삭제
    @State private var showMessageAlert = false
    @State private var showCallAlert = false
    @State private var selectedPhone: String?
    @State private var selectedMessage: String?
    @State private var selectedMessageComment: String?
    
    let messagePairs: [(message: String, comment: String)] = [
        (
            "💌  요즘 날씨가 왔다 갔다 하는데 감기 안 걸렸지?",
            "💡 Tip : 날씨를 핑계로 건강을 묻는 건 부담 없는 방식이에요. 자연스럽고 챙기는 느낌이 살아 있어요."
        ),
        (
            "💌  지나가다가 김치찌개 냄새 맡았는데 갑자기 어릴 때 생각나더라.",
            "💡 Tip : 후각과 음식은 가족과의 추억을 가장 선명하게 꺼내는 감각이에요."
        ),
        (
            "💌  이번 주에 너가 추천해줬던 영화 봤어! 너무 좋더라",
            "💡 Tip : 상대의 취향을 기억해주는 메시지는 특별한 애정을 전달하는 효과가 있어요."
        )
    ]
    
    var body: some View {
        HStack(spacing: 16) {
            if let phone = people.phoneNumber {
                Button {
//                    if let url = URL(string: "tel://\(phone)"), UIApplication.shared.canOpenURL(url) {
//                        UIApplication.shared.open(url)
//                    }
                    let selected = messagePairs.randomElement()!
                    selectedPhone = phone
                    selectedMessage = selected.message
                    selectedMessageComment = selected.comment
                    showCallAlert = true
                } label: {
                    ActionButton(title: "전화걸기", systemImage: "phone.fill", enabled: true)
                }
            } else {
                ActionButton(title: "전화걸기", systemImage: "phone.fill", enabled: false)
            }

            if let phone = people.phoneNumber {
                Button {
//                    if let url = URL(string: "sms:\(phone)"), UIApplication.shared.canOpenURL(url) {
//                        UIApplication.shared.open(url)
//                    }
                    
                    let selected = messagePairs.randomElement()!
                    selectedPhone = phone
                    selectedMessage = selected.message
                    selectedMessageComment = selected.comment
                    showMessageAlert = true
                } label: {
                    ActionButton(title: "문자하기", systemImage: "ellipsis.message.fill", enabled: true)
                }
            } else {
                ActionButton(title: "문자하기", systemImage: "ellipsis.message.fill", enabled: false)
            }
        }
        .alert("추천 메시지로 연락해보세요.", isPresented: $showMessageAlert) {
            
            Button("문자하기", role: .none) {
                if let phone = selectedPhone, let message = selectedMessage {
                    if let url = URL(
                        string: "sms:\(phone)&body=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                    ),
                       UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("\(selectedMessage ?? "")\n\n\(selectedMessageComment ?? "")")
        }
        .alert("추천 메시지로 연락해보세요.", isPresented: $showCallAlert) {
            Button("전화걸기", role: .none) {
                if let phone = selectedPhone {
                    if let url = URL(string: "tel://\(phone)"),
                       UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("\(selectedMessage ?? "")\n\n\(selectedMessageComment ?? "")")
        }
    }
}

private struct ActionButton: View {
    var title: String
    var systemImage: String
    var enabled: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .modifier(Font.Pretendard.h1BoldStyle())
                .foregroundColor(enabled ? .blue01 : .gray02)
            Text(title)
                .modifier(Font.Pretendard.b2MediumStyle())
                .foregroundColor(enabled ? .black : .gray02)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: 48)
        .background(enabled ? Color.bg02 : Color.gray04)
        .cornerRadius(12)
    }
}

private struct ProfileTabBar: View {
    @Binding var selected: ProfileDetailView.Tab

    var body: some View {
        HStack {
            TabButton(title: "프로필", isSelected: selected == .profile)
                .onTapGesture {
                    selected = .profile
                    AnalyticsManager.shared.profileTabLogAnalytics()
                }

            TabButton(title: "기록", isSelected: selected == .records)
                .onTapGesture {
                    selected = .records
                    AnalyticsManager.shared.historyTapLogAnalytics()
                }

        }
    }
}

private struct TabButton: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 9) {
            Text(title)
                .modifier(Font.Pretendard.b2MediumStyle())
                .foregroundColor(isSelected ? .black : .gray02)
            
            Rectangle()
                .fill(isSelected ? Color.blue01 : Color.clear)
                .frame(height: 3)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ProfileInfoSection: View {
    var people: Friend

    var body: some View {
        VStack(spacing: 16) {
            InfoRow(label: "관계", value: displayLabel(for: people.relationship)  ?? "-")
            InfoRow(label: "연락 주기", value: people.frequency?.rawValue ?? "-")
            InfoRow(label: "생일", value: people.birthDay?.formattedYYYYMMDDWithDot() ?? "-")
            InfoRow(label: "기념일", value: "\(people.anniversary?.title ?? "-") (\(people.anniversary?.Date?.formattedYYYYMMDDWithDot() ?? "-"))")
            MemoRow(label: "메모", value: people.memo ?? "-")
        }
    }
    
    private func displayLabel(for rawValue: String?) -> String? {
        switch rawValue {
        case "FRIEND": return "친구"
        case "FAMILY": return "가족"
        case "ACQUAINTANCE": return "지인"
        default: return nil
        }
    }
}

private struct InfoRow: View {
    var label: String
    var value: String

    var body: some View {
        HStack {
            Text(label)
                .modifier(Font.Pretendard.b2MediumStyle())
                .foregroundColor(.gray01)
            Spacer()
            Text(value)
                .modifier(Font.Pretendard.b2MediumStyle())
        }
        .padding()
        .frame(minHeight: 54)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray03))
    }
}

private struct MemoRow: View {
    var label: String
    var value: String
    var initialValue: String = "꼭 기억해야 할 내용을 기록해보세요.\n예) 날생선 X, 작년 생일에 키링 선물함 등"
    
    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            Text(label)
                .modifier(Font.Pretendard.b2MediumStyle())
                .foregroundColor(.gray01)
                .frame(width: 60, alignment: .leading)
            
            Spacer()
            
            Text(value == "-" ? initialValue : value)
                .modifier(Font.Pretendard.b2MediumStyle())
                .foregroundColor(value == "-" ? Color.gray02 : Color.black)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 72, maxHeight:100, alignment: .topLeading)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray03)
        )
    }
}

private struct ConfirmButton: View {
    var title: String
    var isEnabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .modifier(Font.Pretendard.b1MediumStyle())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isEnabled ? Color.blue01 : Color.gray02)
                .cornerRadius(12)
        }
        .disabled(!isEnabled)
        .frame(height: 56)
    }
}

struct CareToastView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image("img_100_character_success")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)

            Text("더 가까워졌어요!")
                .font(Font.Pretendard.b1Medium())
                .foregroundColor(.black)
        }
        .padding(32)
        .frame(width: 255, height: 186)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        )
        .transition(.scale.combined(with: .opacity))
    }
}
