import SwiftUI

struct NotificationInboxView: View {
    @Binding var path: [AppRoute]
    @ObservedObject var notificationViewModel: NotificationViewModel

    var body: some View {
        VStack {
            bodyView
        }
        .onAppear {
            notificationViewModel.loadAllReminders()
            
            AnalyticsManager.shared.trackNotificationInboxLogAnalytics()
        }
        .navigationBarBackButtonHidden()
        .enableSwipeBackGesture()
        .toolbar {
            ToolbarItem(placement: .topBarLeading)  {
                Button(action: {
                    $path.safeRemoveLast()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("알림")
                    }
                    .foregroundColor(.black)
                    .font(Font.Pretendard.b1Bold())
                }
                .padding(.leading, 12)
            }
        }
    }

    private var bodyView: some View {
        VStack {
            if notificationViewModel.visibleReminders.isEmpty {
                VStack(alignment: .center){
                    // TODO tuist image로 어떻게 바꾸는 건가유
                    Image("img_100_character_empty")
                    Text("지금은 챙김 알림이 없어요.\n필요한 순간에 알려드릴게요.")
                        .foregroundColor(Color.gray01)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            } else {
                VStack(spacing: 12) {
                    Button(action: {
                        notificationViewModel.deleteAllReminders()
                    }) {
                        Label("전체 삭제하기", systemImage: "trash")
                    }
                    ReminderListView(path: $path, notificationViewModel: notificationViewModel)
                }
            }
        }
    }
}

struct ReminderListView: View {
    @Binding var path: [AppRoute]
    @ObservedObject var notificationViewModel: NotificationViewModel
    
    var body: some View {
        List {
            ForEach(notificationViewModel.visibleReminders, id: \.self) { reminder in
                ReminderRowView(notificationViewModel: notificationViewModel,
                                reminder: reminder,
                                person: reminder.person,
                                onSelect: { person in
                    
                    let friend = UserSession.shared.user?.friends.filter({$0.id == person.id}).first
                    // friend.id == person.id 비교해야할까요?
                    if let friend = friend {
                        path.append(.personDetail(friend))
                    }
                })
                .listRowBackground(reminder.isRead ? Color.bg02 : Color.white)
            }
            .onDelete(perform: notificationViewModel.deleteReminder)
        }
        .listStyle(.plain)
    }
}

struct ReminderRowView: View {
    @ObservedObject var notificationViewModel: NotificationViewModel
    var reminder: ReminderEntity
    var person: PersonEntity
    var onSelect: (PersonEntity) -> Void

    var body: some View {
        ReminderContent(person: person, reminder: reminder)
            .onTapGesture {
                notificationViewModel.isRead(reminder)
                onSelect(person)
            }
            .background(NavigationLink(value: person) {
                EmptyView()
            }.hidden())
    }
}

private struct ReminderContent: View {
    let person: PersonEntity
    let reminder: ReminderEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text(reminderMessage(for: person, type: NotificationType(rawValue: reminder.type) ?? .regular))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Text(reminder.isRead ? "읽음" : "읽지 않음")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            Text(reminder.date, formatter: Self.dateFormatter)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .padding(.vertical)
        .contentShape(Rectangle())
    }

    private func reminderMessage(for person: PersonEntity, type: NotificationType) -> String {
        switch type {
        case .birthday:
            return "오늘은 \(person.name)님의 생일이에요.\n따뜻한 축하를 전해볼까요?"
        case .anniversary:
            return "\(person.name)님의 소중한 기념일이에요.\n짧게라도 마음을 표현해보세요."
        case .regular, .unknown:
            return "\(person.name)님께 가볍게 안부를 전해보면 어떨까요?"
        }
    }

    private static var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "yy.MM.dd"
        return df
    }
}

struct NotificationInboxView_Previews: PreviewProvider {
    static var previews: some View {
        let mockVM = NotificationViewModel()
        
        // 1. 필요한 경우 mock 데이터 강제 삽입 (ViewModel 내부 구현에 따라 다름)
        // mockVM.visibleReminders = [ ... 가짜 데이터 ... ]

        return NavigationStack {
            NotificationInboxView(
                path: .constant([]),
                notificationViewModel: mockVM
            )
        }
        .environmentObject(UserSession.shared)
    }
}
