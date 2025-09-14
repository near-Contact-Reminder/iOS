import SwiftUI

struct InboxView: View {
    @Binding var path: [AppRoute]
    @ObservedObject var inboxViewModel: InboxViewModel

    var body: some View {
        VStack {
            if inboxViewModel.notifications.isEmpty {
                emptyStateView
            } else {
                notificationListView
            }
        }
        .onAppear {
            inboxViewModel.updateBadgeCount()
            #if DEBUG
            AnalyticsManager.shared.trackNotificationInboxLogAnalytics()
            #endif
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    path.removeLast()
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

    // Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text("알림을 스케줄해보세요!")
                .font(Font.Pretendard.h2Bold())
                .foregroundColor(.gray)
                .padding()
        }
    }

    // Notification List
    private var notificationListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(inboxViewModel.notifications) { notification in
                    NotificationRowView(
                        notification: notification,
                        onTap: {
                            inboxViewModel.handleNotificationTap(notification)
                        },
                        onDelete: {
                            inboxViewModel.deleteNotification(notification)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// Notification Row View
private struct NotificationRowView: View {
    let notification: LocalNotificationModel
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        let isRead = notification.isRead
        let dateString = dateFormatter.string(from: notification.date ?? Date())
        let statusText = isRead ? "읽음" : "읽지않음"

        return VStack(alignment: .leading, spacing: 8) {
            // 알림 내용
            Text(notification.body)
                .font(Font.Pretendard.b2Medium())
                .foregroundColor(isRead ? .gray : .black)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Text(dateString)
                    .font(Font.Pretendard.captionMedium())
                    .foregroundColor(.gray)

                Spacer()

                Text(statusText)
                    .font(Font.Pretendard.captionMedium())
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isRead ? Color.gray.opacity(0.05) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isRead ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
        .onTapGesture {
            onTap()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("삭제", systemImage: "trash")
            }
        }
    }

    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "yy.MM.dd"
        return df
    }
}
