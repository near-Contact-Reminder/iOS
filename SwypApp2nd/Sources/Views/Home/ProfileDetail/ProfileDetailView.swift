import SwiftUI

struct ProfileDetailView: View {
    @ObservedObject var viewModel: ProfileDetailViewModel
    @Binding var path: [AppRoute]
    @State private var selectedTab: Tab = .profile

    enum Tab {
        case profile, records
    }

    var body: some View {
        
        VStack(alignment: .leading, spacing: 32) {
            
            ProfileHeader(people: viewModel.people)
            
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
                    .padding(.top, -82)
                    .opacity(selectedTab == .profile ? 1 : 0)
                HistorySection(people: viewModel.people)
                    .opacity(selectedTab == .records ? 1 : 0)
            }
            
            ConfirmButton(title: "챙김 기록하기") {
                // TODO: - 챙김 기록 API 필요
            }
        }
        .padding(.horizontal, 24)
    }
}

struct CheckInRecord: Identifiable {
    let id = UUID()
    let index: Int
    let date: Date
}

struct HistorySection: View {
    let people: Friend
    
    let records: [CheckInRecord] = (1...14).map {
        CheckInRecord(
            index: $0,
            date: Date().addingTimeInterval(TimeInterval(-$0 * 86400))
        )
    }

    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("챙김 기록")
                    .font(Font.Pretendard.h2Bold())
                    .foregroundColor(.black)

                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(records.sorted(by: { $0.index > $1.index })) { record in
                        VStack(spacing: 8) {
                            Image("img_100_character_success")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 64, height: 64)

                            Text("\(record.index)번째 챙김")
                                .font(Font.Pretendard.captionBold())
                                .foregroundColor(.blue01)

                            Text(record.date.formattedYYYYMMDD())
                                .font(Font.Pretendard.captionMedium())
                                .foregroundColor(.gray02)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}

private struct ProfileHeader: View {
    let people: Friend

    var body: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .topTrailing) {
                // TODO: - Friend의 PresignedURL 사용 Get
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.gray.opacity(0.3))
                
                // TODO: - Friend의 checkRate
                Image("icon_visual_24_emoji_100")
                    .frame(width: 24, height: 24)
                    .offset(x: 0, y: -5)
            }

            VStack(alignment: .leading, spacing: 8) {
                
                Text(people.name)
                    .frame(height: 22)
                    .font(Font.Pretendard.h2Bold())
                    .multilineTextAlignment(.center)
                
                Text("\(people.lastContactAt?.formattedYYYYMMDDMoreCloser() ?? "-")") //MM월dd일 더 가까워졌어요
                    .font(Font.Pretendard.b1Medium())
                    .foregroundColor(Color.blue01)
            }
        }
        

    }
}

private struct ActionButtonRow: View {
    
    var people: Friend
    
    var body: some View {
        HStack(spacing: 16) {
            if let phone = people.phoneNumber {
                Button {
                    if let url = URL(string: "tel://\(phone)"), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    ActionButton(title: "전화걸기", systemImage: "phone.fill", enabled: true)
                }
            } else {
                ActionButton(title: "전화걸기", systemImage: "phone.fill", enabled: false)
            }

            if let phone = people.phoneNumber {
                Button {
                    if let url = URL(string: "sms:\(phone)"), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    ActionButton(title: "문자하기", systemImage: "ellipsis.message.fill", enabled: true)
                }
            } else {
                ActionButton(title: "문자하기", systemImage: "ellipsis.message.fill", enabled: false)
            }
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
                .font(Font.Pretendard.h1Bold())
                .foregroundColor(enabled ? .blue01 : .gray02)
            Text(title)
                .font(Font.Pretendard.b2Medium())
                .foregroundColor(enabled ? .black : .gray02)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: 48)
        .background(enabled ? Color.bg01 : Color.gray04)
        .cornerRadius(12)
    }
}

private struct ProfileTabBar: View {
    @Binding var selected: ProfileDetailView.Tab

    var body: some View {
        HStack {
            TabButton(title: "프로필", isSelected: selected == .profile)
                .onTapGesture { selected = .profile }

            TabButton(title: "기록", isSelected: selected == .records)
                .onTapGesture { selected = .records }

        }
    }
}

private struct TabButton: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(Font.Pretendard.b2Medium())
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
            InfoRow(label: "관계", value: people.relationship ?? "-")
            InfoRow(label: "연락 주기", value: people.frequency?.rawValue ?? "-")
            InfoRow(label: "생일", value: people.birthDay?.formattedYYYYMMDDWithDot() ?? "-")
            InfoRow(label: "기념일", value: "\(people.anniversary?.title ?? "-") (\(people.anniversary?.Date?.formattedYYYYMMDDWithDot() ?? "-"))")
            MemoRow(label: "메모", value: people.memo ?? "-")
        }
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "-" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
}

private struct InfoRow: View {
    var label: String
    var value: String

    var body: some View {
        HStack {
            Text(label)
                .font(Font.Pretendard.b2Medium())
                .foregroundColor(.gray01)
            Spacer()
            Text(value)
                .font(Font.Pretendard.b2Medium())
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
                .font(Font.Pretendard.b2Medium())
                .foregroundColor(.gray01)
                .frame(width: 60, alignment: .leading)
            
            Spacer()
            
            Text(value == "-" ? initialValue : value)
                .font(Font.Pretendard.b2Medium())
                .foregroundColor(value == "-" ? Color.gray02 : Color.black)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
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
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue01)
                .cornerRadius(12)
        }
    }
}


//struct ProfileDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            previewForDevice("iPhone 13 mini")
//            previewForDevice("iPhone 16")
//            previewForDevice("iPhone 16 Pro")
//            previewForDevice("iPhone 16 Pro Max")
//        }
//    }
//    
//    static func previewForDevice(_ deviceName: String) -> some View {
//        ProfileDetailView(
//            viewModel: ProfileDetailViewModel(
//                people: Friend(
//                    id: UUID(),
//                    name: "Test1",
//                    source: ContactSource.kakao,
//                    frequency: CheckInFrequency.monthly,
//                    phoneNumber: "",
//                    birthDay: Date(),
//                    anniversary: AnniversaryModel(title: "결혼기념일", Date: Date()),
//                    //                memo:"Lorem ipsum dolor sit amet consectetur adipiscing elit quisque faucibus ex sapien vitae pellentesque sem placerat in id cursus mi pretium tellus duis convallis tempus leo eu aenean sed diam urna tempo",
//                    lastContactAt: Date()
//                )
//            )
//        )
//    }
//}


