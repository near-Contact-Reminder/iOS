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
                        VStack(spacing: 32) {
                            // 네비게이션 바
                            CustomNavigationBar(
                                showBadge: notificationViewModel.showBadge,
                                onTapMy: { DispatchQueue.main.async { path.append(.my) }
                                    AnalyticsManager.shared.myProfileLogAnalytics()
                                },
                                onTapBell: { DispatchQueue.main.async { path.append(.inbox) }
                                    AnalyticsManager.shared.notificationLogAnalytics()
                                }
                            )

                            // 인사 레이블
                            GreetingSection(userName: userSession.user?.name ?? "사용자",
                                            checkRate: userSession.user?.checkRate ?? 0)

                            // 이번달 챙길 사람
                            ThisMonthSection(peoples: homeViewModel.thisMonthFriends)
                        }

                        // 내 사람들
                        MyPeopleSection(peoples: $homeViewModel.allFriends, path: $path)
                            .ignoresSafeArea()
                            .frame(height: geometry.size.height * 0.6)
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
            homeViewModel.loadMonthlyFriends()

            AnalyticsManager.shared.trackHomeViewLogAnalytics()

        }
        .onReceive(notificationViewModel.$navigateToPerson.compactMap { $0 }) { friend in
            path.removeAll()
            path.append(.personDetail(friend))
        }
    }
}

// MARK: - 커스텀 네비게이션 바
struct CustomNavigationBar: View {

    let showBadge: Bool
    let onTapMy: () -> Void
    let onTapBell: () -> Void

    var body: some View {
        VStack(alignment: .trailing) {
            HStack {
                Spacer()
                Button{
                    onTapMy()
                } label: {
                    Text("MY")
                        .modifier(Font.Pretendard.h2BoldStyle())
                        .foregroundStyle(Color.white)
                }
                Button {
                    onTapBell()
                } label: {
                    if showBadge {
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
    var checkRate: Int

    private var message1: String {
        switch checkRate {
        case 1...30:
            return "오늘은 가볍게"
        case 31...70:
            return "챙김 기록"
        case 71...100:
            return "따뜻한 챙김 덕분"
        default:
            return "누구를 챙길지"
        }
    }

    private var message2: String {
        switch checkRate {
        case 1...30:
            return " 안부를 전해보면 어떨까요?"
        case 31...70:
            return "을 남겨두면\n더 가까워질 수 있어요."
        case 71...100:
            return "에 \n주변 사람들이 행복할 거에요!"
        default:
            return " 정해볼까요?"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(userName)님,")
                .modifier(Font.Pretendard.h1MediumStyle())
                
            (Text(message1)
                .font(Font.Pretendard.h1Bold())
                .tracking(-0.25)
             + Text(message2)
                .font(Font.Pretendard.h1Medium())
                .tracking(-0.25))
            .multilineTextAlignment(.leading)
            
        }
        .foregroundColor(.white)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 이번달 챙길 사람
struct ThisMonthSection: View {
    var peoples: [FriendMonthlyResponse]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("이번달 챙길 사람")
                    .modifier(Font.Pretendard.b1BoldStyle())
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
                            .modifier(Font.Pretendard.b2MediumStyle())
                            .foregroundColor(.white.opacity(0.8))
                    )
                    .padding(.horizontal, 24)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(peoples.sorted(by: { lhs, rhs in
                            lhs.nextContactAt < rhs.nextContactAt
                        }), id: \.friendId) { contact in
                            ThisMonthContactCell(contact: contact) { selected in
                                // TODO: 상세 네비게이션 연결 -> 이거 지금 어떻게 연결 되고 있는 걸까요 ㅋㅋ
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
    let contact: FriendMonthlyResponse
    let onTap: (FriendMonthlyResponse) -> Void

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
                    .modifier(Font.Pretendard.b1BoldStyle())
                    .foregroundColor(.black)
                    .lineLimit(1)

                if dDayString != "D-DAY" {
                    Text(dDayString)
                        .modifier(Font.Pretendard.b2BoldStyle())
                        .foregroundColor(Color.gray02)
                } else {
                    Text(dDayString)
                        .modifier(Font.Pretendard.b2BoldStyle())
                        .foregroundColor(Color.blue01)
                }

            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white)
            .cornerRadius(12)
        }
    }

    var categoryIconName: String? {
        switch contact.type {
        case "MESSAGE": return "icon_visual_mail"
        case "BIRTHDAY": return "icon_visual_cake"
        case "ANNIVERSARY": return "icon_visual_24_heart"
        default: return nil
        }
    }
    
    var dDayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy-MM-dd"
        guard let target = formatter.date(from: contact.nextContactAt) else {
            return ""
        }

        let today = Calendar.current.startOfDay(for: Date().startOfDayInKorea())
        let targetDay = Calendar.current.startOfDay(for: target.startOfDayInKorea())
        let diff = Calendar.current.dateComponents(
            [.day],
            from: today,
            to: targetDay
        ).day ?? 0

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
                    .modifier(Font.Pretendard.h2BoldStyle())
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
                            AnalyticsManager.shared.addPersonLogAnalytics()
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
                            .modifier(Font.Pretendard.b1MediumStyle())
                            .foregroundColor(.gray02)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .frame(height: geometry.size.height * 1)
                } else {
                    VStack(alignment: .center, spacing: 10) {
                        TabView(selection: $currentPage) {
                            ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                                StarPositionLayout(peoples: $peoples , pageIndex: index) { selected in
                                    path.append(.personDetail(selected))
                                    AnalyticsManager.shared.selectPersonLogAnalytics()
                                }
                                .tag(index)
                                .environmentObject(HomeViewModel())
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
                        .padding(.bottom)
                    }
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerSize: CGSize(width: 24, height: 24)))
    }
}

struct StarPositionLayout: View {
    @Binding var peoples: [Friend]
    @EnvironmentObject var homeViewModel: HomeViewModel
    let pageIndex: Int
    let onTap: (Friend) -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var draggingIndex: Int? = nil
    @EnvironmentObject var userSession: UserSession


    /// 내 사람들 인원별 레이아웃
    private func personPositions(for count: Int) -> [CGPoint] {
        switch count {
        case 0:
            return []
        case 1:
            // 1명
            return [
                CGPoint(x:   -80, y: 0)
            ]
        case 2:
            // 2명
            return [
                CGPoint(x:   0,  y: -80),
                CGPoint(x: -100, y:   80)
            ]
        case 3:
            // 3명
            return [
                CGPoint(x:   0,  y: -100),
                CGPoint(x: -100, y:   30),
                CGPoint(x:  100, y:   30)
            ]
        case 4:
            // 4명
            return [
                CGPoint(x:   0,  y: -110),   // 위
                CGPoint(x: -120, y:  -10),   // 왼쪽 중간
                CGPoint(x:  120, y:  -10),   // 오른쪽 중간
                CGPoint(x: -80, y:   120)    // 왼쪽 아래
            ]
        default:
            // 5명
            return [
                CGPoint(x:    0,  y: -110),
                CGPoint(x: -120,  y:  -20),
                CGPoint(x:  120,  y:  -20),
                CGPoint(x:  -80,  y:  120),
                CGPoint(x:   80,  y:  120)
            ]
        }
    }

    ///  “사람 추가(+)” button
    private func addButtonPosition(for count: Int) -> CGPoint? {
        switch count {
        case 0:  return CGPoint(x:    0, y:    0)   // 빈 상태 중앙
        case 1:  return CGPoint(x:  80, y:    0)   // 오른쪽 중앙
        case 2:  return CGPoint(x:  100, y:   80)   // 오른쪽 아래
        case 3:  return CGPoint(x:    0, y:  150)   // 맨 아래 중앙
        case 4:  return CGPoint(x:  80, y:   120)   // 오른쪽 아래
        default: return nil                         // 5명 이상 → 표시 안함
        }
    }

    var body: some View {
        ZStack {
            let start = pageIndex * 5
            let end = min(start + 5, peoples.count)
            let pagePeople = Array(peoples[start..<end])
            let personPositions = personPositions(for: pagePeople.count)
            ForEach(start..<end, id: \.self) { i in
                let indexInPage = i - start
                let person = peoples[i]
                let isDragging = draggingIndex == i
                let offset = isDragging ? dragOffset : .zero

                PersonCircleView(people: person, onTap: onTap)
                    .offset(
                        x: personPositions[indexInPage].x + offset.width,
                        y: personPositions[indexInPage].y + offset.height
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
                                let draggingPos = personPositions[draggingInPage]
                                let currentPosition = CGPoint(
                                    x: draggingPos.x + dragOffset.width,
                                    y: draggingPos.y + dragOffset.height
                                )

                                var closest = draggingInPage
                                var minDist = CGFloat.infinity
                                for (j, pos) in personPositions.enumerated() {
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
                                    // 서버에 변경된 순서 전송.
                                    let draggingFriend = peoples[dragging]
                                    let targetFriend = peoples[targetIndex]
                                    homeViewModel
                                        .patchFriendOrder(
                                            targetID: draggingFriend.id.uuidString,
                                            newPosition: dragging
                                        )
                                    homeViewModel
                                        .patchFriendOrder(
                                            targetID: targetFriend.id.uuidString,
                                            newPosition: targetIndex
                                        )
                                }

                                draggingIndex = nil
                                dragOffset = .zero

                            }
                    )
                    .animation(.spring(), value: dragOffset)
            }
            // 추가 버튼
            if let addPos = addButtonPosition(for: pagePeople.count) {
                Button {
                    userSession.appStep = .registerFriends
                } label: {
                    VStack {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundColor(Color.blue01)
                            .frame(width: 80, height: 80)
                            .background(Color.bg01)
                            .clipShape(Circle())
                        Text("사람 추가")
                            .modifier(Font.Pretendard.b2BoldStyle())
                            .foregroundColor(.black)
                    }
                }
                .offset(x: addPos.x + 4, y: addPos.y - 8)
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
        guard let date = people.lastContactAt else { return "챙김 기록이 없어요" }
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
                        let placeholders = ["_img_64_user1", "_img_64_user2", "_img_64_user3"]
                        let index = abs(people.id.hashValue) % placeholders.count
                        Image(placeholders[index])
                            .resizable()
                    }
                }
                .frame(width: 80, height: 80)
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
                .modifier(Font.Pretendard.b2BoldStyle())
                .foregroundColor(.black)
            HStack(spacing: 4) {
                Text(formattedDate)
                    .modifier(Font.Pretendard.captionMediumStyle())
                    .foregroundColor(Color.gray02)
                if formattedDate != "챙김 기록이 없어요" {
                    Image("icon_check_blue")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 8, height: 8)
                }
            }
            
        }
    }
}
