import CoreData
import SwiftUI

struct Anniversary: Identifiable {
    let id = UUID()
    var label: String
    var date: Date?
}

struct ProfileEditView: View {
    @StateObject var profileEditViewModel = ProfileEditViewModel()
    @StateObject var notificationViewModel = NotificationViewModel()
    @Environment(\.presentationMode) var presentationMode

    @State private var name: String = ""
    @State private var relationship: String = "친구"
    @State private var contactFrequency: String = "매주"
    @State private var birthday: Date? = nil
    @State private var anniversaries: [Anniversary] = []
    @State private var memo: String = ""

    let contactFrequencies = ["매일", "매주", "2주", "매달", "매분기", "6개월", "매년"]

    var body: some View {
        VStack {
            Form {
                Section(header: Text("이름")) {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("20자 내로 이름을 입력해주세요", text: $name)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                            .onChange(of: name) {
                                if name.count > 20 {
                                    name = String(name.prefix(20))
                                }
                            }
                    }
                }
                Section(header: Text("관계")) {
                    Picker("관계", selection: $relationship) {
                        Text("친구").tag("친구")
                        Text("가족").tag("가족")
                        Text("지인").tag("지인")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                Section(header: Text("연락 주기")) {
                    Picker("연락 주기", selection: $contactFrequency) {
                        ForEach(contactFrequencies, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                WheelDatePicker(title: "생일", showEmptyYear: true, limitToPast: true, date: $birthday)

                Section(header: Text("기념일")) {
                    ForEach($anniversaries) { $anniversary in
                        // TODO: Add delete
                        // TODO: Design enhancement - HStack might be better
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("기념일 이름", text: $anniversary.label)
                                .autocorrectionDisabled(true)
                                .textInputAutocapitalization(.never)
                            WheelDatePicker(title: "", showEmptyYear: true, limitToPast: false, date: $anniversary.date)
                        }
                        .padding(.vertical, 4)
                    }

                    Button("일정 추가") {
                        anniversaries.append(Anniversary(label: "", date: nil))
                    }
                }

                Section(header: Text("메모")) {
                    VStack(alignment: .leading, spacing: 4) {
                        ZStack(alignment: .topLeading) {
                            if memo.isEmpty {
                                Text("""
                                꼭 기억해야 할 내용을 기록해보세요.
                                예) 날생선 X, 작년 생일에 키링 선물함 등
                                """)
                                .foregroundColor(.gray)
                                .padding(8)
                            }

                            TextEditor(text: $memo)
                                .onChange(of: memo) {
                                    if memo.count > 100 {
                                        memo = String(memo.prefix(100))
                                    }
                                }
                                .autocorrectionDisabled(true)
                                .textInputAutocapitalization(.never)
                                .frame(height: 100)
                        }

                        HStack {
                            Spacer()
                            Text("\(memo.count)/100")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }

            Button(action: {
                let person = profileEditViewModel.addNewPerson(name: name, relationship: relationship, birthday: birthday, anniversary: anniversaries.first?.date, reminderInterval: contactFrequency, memo: memo) // TODO 이거 context save로 바꿀 수 있다고?
//                notificationViewModel.scheduleAllReminders(for: person)
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("완료")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
    }
}

struct WheelDatePicker: View {
    let title: String
    let showEmptyYear: Bool
    let limitToPast: Bool
    @Binding var date: Date?
    @State private var isPickerVisible = false

    var body: some View {
        Section(header: Text(title)) {
            Button {
                isPickerVisible.toggle()
            } label: {
                HStack {
//                    Text("날짜 선택")
//                        .foregroundColor(.primary)
//                    Spacer()
                    Text(date != nil ? formattedDate(date!) : "선택 안함")
                        .foregroundColor(date != nil ? .primary : .gray)
                }
            }

            let maxDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            let dateRange = limitToPast ? Date.distantPast...maxDate : Date.distantPast...Date.distantFuture

            if isPickerVisible {
                // TODO: limit date range if needed (bday should only have date options prior to today)
                DatePicker(
                    "",
                    selection: Binding(
                        get: { date ?? Date() },
                        set: { date = $0 }
                    ),
                    in: dateRange,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter.string(from: date)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        // Replace with valid PersonEntity for preview
        ProfileEditView()
    }
}
