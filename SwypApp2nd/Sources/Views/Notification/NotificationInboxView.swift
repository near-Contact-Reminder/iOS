import SwiftUI

struct NotificationInboxView: View {
    @StateObject var notificationViewModel = NotificationViewModel()
    @Binding var path: [AppRoute]
    
    var body: some View {
        VStack {
            headerView
            bodyView
        }
        .navigationTitle("알림 목록")
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
            if notificationViewModel.reminders.isEmpty {
                Text("알림을 추가해보세요!")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                VStack {
                    Button(action: {
                        notificationViewModel.deleteAllReminders()
                    }) {
                        Label("전체 삭제하기", systemImage: "trash")
                    }
                    ReminderListView(onSelect: { person in
                        path.append(.person(person))
                    })
                    .environmentObject(notificationViewModel)
                }
            }
        }
    }
}

struct ReminderListView: View {
    @EnvironmentObject var notificationViewModel: NotificationViewModel
    var onSelect: (PersonEntity) -> Void

    var body: some View {
        List {
            ForEach(notificationViewModel.reminders, id: \.self) { reminder in
                ReminderRowView(reminder: reminder, onSelect: onSelect)
                .environmentObject(notificationViewModel)
                .listRowBackground(reminder.isRead ? Color.readBlue : Color.white)
            }.onDelete(perform: notificationViewModel.deleteReminder)
        }
        .listStyle(.plain)
    }
}

struct ReminderRowView: View {
    @EnvironmentObject var notificationViewModel: NotificationViewModel
    var reminder: ReminderEntity
    var onSelect: (PersonEntity) -> Void

    var body: some View {
        if let person = reminder.person {
            ReminderContent(person: person, reminder: reminder)
                .onTapGesture {
                    notificationViewModel.markAsRead(reminder)
                    onSelect(person)
                }
                .background(NavigationLink(value: person) {
                    EmptyView()
                }.hidden())
        } else {
            Text("❗️유효하지 않은 알림입니다")
                .foregroundColor(.red)
        }
    }
}

private struct ReminderContent: View {
    let person: PersonEntity
    let reminder: ReminderEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text(reminderMessage(for: person))
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

    private func reminderMessage(for person: PersonEntity) -> String {
//        switch reminder.type {
//            case person.birthday:
//                return "오늘은 \(person.name)님의 생일이에요.\n 따뜻한 축하를 전해볼까요?"
//            case person.anniversary:
//                return "\(person.name)님의 소중한 기념일이에요.\n 짧게라도 마음을 표현해보세요."
//        default:
//            return "\(person.name)님께 가볍게 안부를 전해보면 어떨까요?"
//        }
        return "\(person.name)님께 가볍게 안부를 전해보면 어떨까요?"
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
