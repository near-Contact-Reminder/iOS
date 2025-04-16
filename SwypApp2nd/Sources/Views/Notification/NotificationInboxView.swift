import SwiftUI

struct NotificationInboxView: View {
    @Binding var path: [AppRoute]
    @EnvironmentObject var notificationViewModel: NotificationViewModel

    var body: some View {
        VStack {
            headerView
            bodyView
        }
        .navigationTitle("알림")
        .onAppear {
            notificationViewModel.loadAllReminders()
        }
    }

    private var headerView: some View {
        HStack {
            Spacer()
            NavigationLink(destination: ProfileEditView()) {
                Image(systemName: "gear")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .padding()
            }
        }
    }

    private var bodyView: some View {
        VStack {
            if notificationViewModel.visibleReminders.isEmpty {
                Text("오늘 예정된 알림이 없어요!")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    Button(action: {
                        notificationViewModel.deleteAllReminders()
                    }) {
                        Label("전체 삭제하기", systemImage: "trash")
                    }
                    ReminderListView(path: $path, reminders: notificationViewModel.visibleReminders)
                }
            }
        }
    }
}

struct ReminderListView: View {
    @EnvironmentObject var notificationViewModel: NotificationViewModel
    @Binding var path: [AppRoute]
    var reminders: [ReminderEntity]

    var body: some View {
        List {
            ForEach(notificationViewModel.visibleReminders, id: \.self) { reminder in
                ReminderRowView(reminder: reminder, person: reminder.person, onSelect: { person in
                    path.append(.person(person))})
                    .listRowBackground(reminder.isRead ? Color.readBlue : Color.white)
            }
            .onDelete(perform: notificationViewModel.deleteReminder)
        }
        .listStyle(.plain)
    }
}

struct ReminderRowView: View {
    @EnvironmentObject var notificationViewModel: NotificationViewModel
    var reminder: ReminderEntity
    var person: PersonEntity
    var onSelect: (PersonEntity) -> Void

    var body: some View {
        ReminderContent(person: person, reminder: reminder)
            .onTapGesture {
                notificationViewModel.markAsRead(reminder)
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
    struct PreviewWrapper: View {
        @State var dummyPath: [AppRoute] = []

        var body: some View {
            NotificationInboxView(path: $dummyPath)
                .environmentObject(UserSession.shared)
                .environmentObject(NotificationManager.shared.notificationViewModel)
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
