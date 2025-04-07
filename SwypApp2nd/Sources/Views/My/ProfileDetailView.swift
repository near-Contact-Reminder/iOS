import SwiftUI

struct ProfileDetailView: View {
    var person: PersonEntity
    @State private var selectedTab: Tab = .profile

    enum Tab {
        case profile, records
    }

    var body: some View {
        VStack(spacing: 16) {
            ProfileHeader(person: person)
            ActionButtonRow()
            ProfileTabBar(selected: $selectedTab)
            
            if selectedTab == .profile {
                ProfileInfoSection(person: person)
            } else {
                Text("기록 탭")
            }
            
            Spacer()
            
            ConfirmButton(title: "챙김 기록하기") {
                // TODO
            }
        }
        .padding()
    }
}

private struct ProfileHeader: View {
    var person: PersonEntity

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.gray.opacity(0.3))

                Text("😐")
                    .font(.title2)
                    .offset(x: 0, y: -5)
            }

            VStack(alignment: .leading, spacing: 4) {
                
                Text(person.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text("데이터 연동 필요")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
    }
}

private struct ActionButtonRow: View {
    var body: some View {
        HStack(spacing: 16) {
            ActionButton(title: "전화걸기", systemImage: "phone")
            ActionButton(title: "문자하기", systemImage: "ellipsis.message")
        }
    }
}

private struct ActionButton: View {
    var title: String
    var systemImage: String

    var body: some View {
        VStack {
            Image(systemName: systemImage)
                .font(.title3)
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .clipShape(Circle())
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

private struct ProfileTabBar: View {
    @Binding var selected: ProfileDetailView.Tab

    var body: some View {
        HStack {
            TabButton(title: "프로필", selected: $selected, tab: .profile)
            TabButton(title: "기록", selected: $selected, tab: .records)
        }
        .padding(6)
        .background(Color.gray.opacity(0.1))
        .clipShape(Capsule())
    }
}

private struct TabButton: View {
    var title: String
    @Binding var selected: ProfileDetailView.Tab
    var tab: ProfileDetailView.Tab

    var body: some View {
        Button(action: {
            selected = tab
        }) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(selected == tab ? .white : .gray)
                .padding(.vertical, 6)
                .padding(.horizontal, 20)
                .background(selected == tab ? Color.blue : Color.clear)
                .clipShape(Capsule())
        }
    }
}

private struct ProfileInfoSection: View {
    var person: PersonEntity

    var body: some View {
        VStack(spacing: 12) {
            InfoRow(label: "관계", value: person.relationship)
            InfoRow(label: "연락 주기", value: person.reminderInterval)
            InfoRow(label: "생일", value: formatDate(person.birthday))
            InfoRow(label: "기념일", value: "결혼기념일 (\(formatDate(person.anniversary)))")
            InfoRow(label: "메모", value: person.memo ?? "-")
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
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.subheadline)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.2)))
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
                .background(Color.blue)
                .cornerRadius(12)
        }
    }
}
struct ProfileDetail_Preview: PreviewProvider {
    static var previews: some View {
        // Replace with valid PersonEntity for preview
        let context = CoreDataStack.shared.context
        let mockPerson = PersonEntity.mockPerson(context: context)
        
        ProfileDetailView(person: mockPerson)
    }
}



