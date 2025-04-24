import SwiftUI

public struct HomeView: View {

    @ObservedObject var homeViewModel: HomeViewModel
    @ObservedObject var notificationViewModel: NotificationViewModel

    @State private var showInbox = false
    @Binding var path:[AppRoute]

    @EnvironmentObject var userSession: UserSession
    
    
    public var body: some View {
        VStack(spacing: 24) {
                    
            ZStack(alignment: .top) {
                Image("img_bg")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                GeometryReader { geometry in
                    VStack {
                        VStack(spacing: 24) {
                            // 네비게이션 바
                            CustomNavigationBar(badgeCount: notificationViewModel.badgeCount,
                                                onTapMy: {DispatchQueue.main.async {
                                path.append(.my)} },
                                                onTapBell: { DispatchQueue.main.async { path.append(.inbox) }
                            })
                            
                            // 인사 레이블
                            GreetingSection(userName: userSession.user?.name ?? "사용자")
                            
                            // 이번달 챙길 사람
                            ThisMonthSection(peoples: homeViewModel.thisMonthFriends)
                        }
                        
                        // 내 사람들
                        MyPeopleSection(peoples: $homeViewModel.allFriends, path: $path)
                            .ignoresSafeArea()
                            .frame(height: geometry.size.height * 0.65)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(.top, 44)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .environmentObject(userSession)
        .onAppear {
            homeViewModel.loadFriendList()
        }
    }
}

// MARK: - 커스텀 네비게이션 바
struct CustomNavigationBar: View {
    
    let badgeCount: Int
    let onTapMy: () -> Void
    let onTapBell: () -> Void
    
    var body: some View {
        VStack(alignment: .trailing) {
            HStack {
                Spacer()
                Button{
                    onTapMy()
                } label: {
                    Text("My")
                        .font(Font.Pretendard.h2Bold())
                        .foregroundStyle(Color.white)
                }
                Button {
                    onTapBell()
                } label: {
                    if badgeCount > 0 {
                        Button(action: onTapBell) {
                            Image(systemName: "bell.badge.fill")
                                .foregroundStyle(Color.white)
                                .frame(width: 32, height: 32)
                        }
                    } else {
                        Button(action: onTapBell) {
                            Image(systemName: "bell.fill")
                                .foregroundStyle(Color.white)
                                .frame(width: 32, height: 32)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
}


// MARK: - 상단 레이블
struct GreetingSection: View {
    var userName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(userName)님,")
                .font(Font.Pretendard.h1Medium())
                .foregroundColor(.white)
            HStack {
                Text("누구를 챙길지 ")
                    .font(Font.Pretendard.h1Bold())
                    .foregroundColor(.white)
                + Text("정해볼까요?")
                    .font(Font.Pretendard.h1Medium())
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 이번달 챙길 사람
struct ThisMonthSection: View {
    var peoples: [Friend]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("이번달 챙길 사람")
                    .font(Font.Pretendard.b1Bold())
                    .foregroundColor(.white)
                Spacer()
                // TODO: - 2차때..
//                if !peoples.isEmpty {
//                    Button {
//                        
//                    } label: {
//                        HStack {
//                            Text("전체보기")
//                                .font(Font.Pretendard.b2Medium())
//                                .foregroundColor(.gray03)
//                            Image("icon_12_arrow_right")
//                        }
//                    }
//                }
            }
            .padding(.horizontal, 24)

            if peoples.isEmpty {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 48)
                    .overlay(
                        Text("이번달은 챙길 사람이 없네요.")
                            .font(Font.Pretendard.b1Medium())
                            .foregroundColor(.white.opacity(0.8))
                    )
                    .padding(.horizontal, 24)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(peoples, id: \.id) { contact in
                            ThisMonthContactCell(contact: contact) { selected in
                                // TODO: 상세 네비게이션 연결
                                print("\(selected.name) tapped")
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }
}

struct ThisMonthContactCell: View {
    let contact: Friend
    let onTap: (Friend) -> Void

    var body: some View {
        Button {
            onTap(contact)
        } label: {
            HStack {
                if let iconName = categoryIconName {
                    Image(iconName)
                        .resizable()
                        .frame(width: 24, height: 24)
                } else {
                    Image("icon_visual_mail")
                        .resizable()
                        .frame(width: 24, height: 24)
                }

                Text(contact.name)
                    .font(.Pretendard.b1Bold())
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                Text(dDayString)
                    .font(.Pretendard.b2Bold())
                    .foregroundColor(Color.blue01)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white)
            .cornerRadius(12)
        }
    }

    var emojiImageName: String {
        guard let rate = contact.checkRate else {
            return "icon_visual_24_emoji_0"
        }
        switch rate {
        case 0...30: return "icon_visual_24_emoji_0"
        case 31...60: return "icon_visual_24_emoji_50"
        default: return "icon_visual_24_emoji_100"
        }
    }

    var categoryIconName: String? {
        switch contact.remindCategory {
        case .message: return "icon_visual_mail"
        case .birth: return "icon_visual_cake"
        case .anniversary: return "icon_visual_24_heart"
        case .none: return nil
        }
    }

    var dDayString: String {
        guard let target = contact.nextContactAt else { return "" }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let targetDay = calendar.startOfDay(for: target)
        let diff = calendar.dateComponents([.day], from: today, to: targetDay).day ?? 0

        if diff == 0 {
            return "D-DAY"
        } else if diff > 0 {
            return "D-\(diff)"
        } else {
            return "D+\(-diff)"
        }
    }
}


// MARK: - 내 사람들
struct MyPeopleSection: View {
    @State private var currentPage = 0
    @Binding var peoples: [Friend]
    @Binding var path: [AppRoute]
    @State private var showEllipsisOptions = false
    @EnvironmentObject var userSession: UserSession
    private var pages: [[Friend]] {
        stride(from: 0, to: peoples.count, by: 5).map {
            Array(peoples[$0..<min($0 + 5, peoples.count)])
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("내 사람들")
                    .font(Font.Pretendard.h1Bold())
                    .foregroundStyle(Color.black)
                Spacer()
                Button {
                    showEllipsisOptions = true
                } label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .font(Font.Pretendard.h2Bold())
                        .foregroundStyle(Color.black)
                }
                .confirmationDialog("옵션 선택", isPresented: $showEllipsisOptions, titleVisibility: .visible) {
                    Button("사람 추가") {
                        userSession.appStep = .registerFriends
                    }
                    // TODO: - 순서 편집으로 내 사람들 순서 변경 로직 추가하기.
//                    Button("순서 편집") {
//                        // 순서 편집 로직
//                        print("순서 편집")
//                    }
                    Button("취소", role: .cancel) { }
                }
            }
            .padding(.top)
            .padding(.horizontal, 24)

            GeometryReader{ geometry in
                if peoples.isEmpty {
                    // 내 사람들 없는 경우
                    VStack(alignment: .center, spacing: 8) {
                        Button {
                            UserSession.shared.appStep = .registerFriends
                        } label: {
                            Image(systemName: "plus")
                                .font(.title)
                                .foregroundColor(.blue)
                                .frame(width: 64, height: 64)
                                .background(Color.bg01)
                                .clipShape(Circle())
                        }
                        Text("가까워 지고 싶은 사람을\n추가해보세요.")
                            .multilineTextAlignment(.center)
                            .font(Font.Pretendard.b1Medium())
                            .foregroundColor(.gray02)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .frame(height: geometry.size.height * 1)
                } else {
                    VStack(alignment: .center, spacing: 10) {
                        TabView(selection: $currentPage) {
                            ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                                StarPositionLayout(peoples: $peoples , pageIndex: index) { selected in
                                    // TODO: - 친구 상세 뷰 이동
                                    path.append(.personDetail(selected))
                                    print("\(selected.name) tapped")
                                    print("\(selected.id) tapped")
                                }
                                .tag(index)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                        // 페이지 인디케이터
                        HStack(spacing: 6) {
                            ForEach(0..<pages.count, id: \.self) { index in
                                Circle()
                                    .fill(currentPage == index ? Color.black : Color.gray.opacity(0.3))
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .padding(.bottom, 44)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerSize: CGSize(width: 24, height: 24)))
    }
}

struct StarPositionLayout: View {
    @Binding var peoples: [Friend]
    let pageIndex: Int
    let onTap: (Friend) -> Void
        
    @State private var dragOffset: CGSize = .zero
    @State private var draggingIndex: Int? = nil
    @EnvironmentObject var userSession: UserSession

    let positions: [CGPoint] = [
        CGPoint(x: 0, y: -120),
        CGPoint(x: -110, y: -30),
        CGPoint(x: 110, y: -30),
        CGPoint(x: -60, y: 110),
        CGPoint(x: 60, y: 110)
    ]
    
    var body: some View {
        ZStack {
            let start = pageIndex * 5
            let end = min(start + 5, peoples.count)
            let pagePeople = Array(peoples[start..<end])
            ForEach(start..<end, id: \.self) { i in
                let indexInPage = i - start
                let person = peoples[i]
                let isDragging = draggingIndex == i
                let offset = isDragging ? dragOffset : .zero

                PersonCircleView(people: person, onTap: onTap)
                    .offset(
                        x: positions[indexInPage].x + offset.width,
                        y: positions[indexInPage].y + offset.height
                    )
                    .gesture(
                        LongPressGesture(minimumDuration: 0.2)
                            .onEnded { _ in
                                draggingIndex = i
                            }
                            .sequenced(before: DragGesture())
                            .onChanged { value in
                                switch value {
                                case .second(true, let drag?):
                                    dragOffset = drag.translation
                                default: break
                                }
                            }
                            .onEnded { _ in
                                guard let dragging = draggingIndex else { return }

                                let draggingInPage = dragging - start
                                let draggingPos = positions[draggingInPage]
                                let currentPosition = CGPoint(
                                    x: draggingPos.x + dragOffset.width,
                                    y: draggingPos.y + dragOffset.height
                                )

                                var closest = draggingInPage
                                var minDist = CGFloat.infinity
                                for (j, pos) in positions.enumerated() {
                                    if j == draggingInPage { continue } // 자기 자신 제외
                                    let dist = hypot(pos.x - currentPosition.x, pos.y - currentPosition.y)
                                    if dist < minDist {
                                        minDist = dist
                                        closest = j
                                    }
                                }

                                let targetIndex = start + closest
                                if targetIndex != dragging,
                                   peoples.indices.contains(dragging),
                                   peoples.indices.contains(targetIndex) {
                                    peoples.swapAt(dragging, targetIndex)
                                    for (idx, _) in peoples.enumerated() {
                                        peoples[idx].position = idx
                                    }
                                    
                                    print("=== 현재 position 순서 ===")
                                    for contact in peoples {
                                        print(
                                            "\(contact.name): position \(contact.position ?? -1)"
                                        )
                                    }
                                    // TODO: - 서버에 변경된 순서 전송.
                                }

                                draggingIndex = nil
                                dragOffset = .zero
                                
                            }
                    )
                    .animation(.spring(), value: dragOffset)
            }
            // 추가 버튼 삽입 로직
            if pagePeople.count < 5 {
                let addIndex = pagePeople.count
                Button {
                    userSession.appStep = .registerFriends
                } label: {
                    VStack {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundColor(.blue)
                            .frame(width: 64, height: 64)
                            .background(Color.bg01)
                            .clipShape(Circle())
                        Text("사람 추가")
                            .font(Font.Pretendard.b1Medium())
                            .foregroundColor(.black)
                    }
                }
                .offset(
                    x: positions[addIndex].x,
                    y: positions[addIndex].y
                )
            }
        }
        .frame(height: 240)
    }
}

struct PersonCircleView: View {
    let people: Friend
    let onTap: (Friend) -> Void
    
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

    var formattedDate: String {
        guard let date = people.lastContactAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yy.MM.dd"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Button {
                    onTap(people)
                } label: {
                    if let image = people.image {
                        Image(uiImage: image)
                            .resizable()
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: 88, height: 88)
                .clipShape(Circle())
                .overlay(
                    Image(emojiImageName)
                        .resizable()
                        .frame(width: 26, height: 26)
                        .offset(x: -5, y: -5),
                    alignment: .topTrailing
                )
            }
            
            Text(people.name)
                .font(Font.Pretendard.b2Bold())
            Text(formattedDate)
                .font(Font.Pretendard.captionMedium())
                .foregroundColor(Color.gray02)
        }
    }
}

//struct HomeView_Previews: PreviewProvider {
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
//        let fakeFriends = [
//            Friend(
//                id: UUID(),
//                name: "정종원1",
//                image: nil,
//                imageURL: nil,
//                source: .kakao,
//                frequency: CheckInFrequency.none,
//                remindCategory: .message,
//                nextContactAt: Calendar.current
//                    .date(byAdding: .day, value: 0, to: Date()), // 오늘
//                lastContactAt: Calendar.current
//                    .date(byAdding: .day, value: -1, to: Date()),
//                checkRate: 20,
//                position: 0
//            ),
//            Friend(
//                id: UUID(),
//                name: "정종원2",
//                image: nil,
//                imageURL: nil,
//                source: .phone,
//                frequency: CheckInFrequency.none,
//                remindCategory: .anniversary,
//                nextContactAt: Calendar.current
//                    .date(byAdding: .day, value: 2, to: Date()), // D-2
//                lastContactAt: Calendar.current
//                    .date(byAdding: .day, value: -3, to: Date()),
//                checkRate: 45,
//                position: 1
//            ),
//            Friend(
//                id: UUID(),
//                name: "정종원3",
//                image: nil,
//                imageURL: nil,
//                source: .kakao,
//                frequency: CheckInFrequency.none,
//                remindCategory: .message,
//                nextContactAt: Calendar.current
//                    .date(byAdding: .day, value: -1, to: Date()), // D+1
//                lastContactAt: Calendar.current
//                    .date(byAdding: .day, value: -7, to: Date()),
//                checkRate: 65,
//                position: 2
//            ),
//            Friend(
//                id: UUID(),
//                name: "정종원4",
//                image: nil,
//                imageURL: nil,
//                source: .phone,
//                frequency: CheckInFrequency.none,
//                remindCategory: .message,
//                nextContactAt: Calendar.current
//                    .date(byAdding: .day, value: 7, to: Date()), // D-7
//                lastContactAt: Calendar.current
//                    .date(byAdding: .day, value: -10, to: Date()),
//                checkRate: 85,
//                position: 3
//            ),
//            Friend(
//                id: UUID(),
//                name: "정종원5",
//                image: nil,
//                imageURL: nil,
//                source: .phone,
//                frequency: CheckInFrequency.none,
//                remindCategory: .birth,
//                nextContactAt: Calendar.current
//                    .date(byAdding: .day, value: 15, to: Date()), // D-15
//                lastContactAt: Calendar.current
//                    .date(byAdding: .day, value: -14, to: Date()),
//                checkRate: 30,
//                position: 4
//            ),
//            Friend(
//                id: UUID(),
//                name: "정종원6",
//                image: nil,
//                imageURL: nil,
//                source: .phone,
//                frequency: CheckInFrequency.none,
//                remindCategory: .message,
//                nextContactAt: Calendar.current
//                    .date(byAdding: .day, value: 7, to: Date()), // D-7
//                lastContactAt: Calendar.current
//                    .date(byAdding: .day, value: -10, to: Date()),
//                checkRate: 85,
//                position: 3
//            ),
//            Friend(
//                id: UUID(),
//                name: "정종원7",
//                image: nil,
//                imageURL: nil,
//                source: .phone,
//                frequency: CheckInFrequency.none,
//                remindCategory: .birth,
//                nextContactAt: Calendar.current
//                    .date(byAdding: .day, value: 15, to: Date()), // D-15
//                lastContactAt: Calendar.current
//                    .date(byAdding: .day, value: -14, to: Date()),
//                checkRate: 30,
//                position: 4
//            )
//        ]
//        
//        UserSession.shared.user = User(id: "", name: "프리뷰", friends: fakeFriends, loginType: .kakao, serverAccessToken: "", serverRefreshToken: "")
//        
//        let viewModel = HomeViewModel()
//        viewModel.loadPeoplesFromUserSession()
//        
//        return HomeView(
//            homeViewModel: viewModel,
//            notificationViewModel: NotificationViewModel(),
//            path: .constant([])
//        )
//        .environmentObject(UserSession.shared)
//        .previewDevice(PreviewDevice(rawValue: deviceName))
//        .previewDisplayName(deviceName)
//    }
//}
