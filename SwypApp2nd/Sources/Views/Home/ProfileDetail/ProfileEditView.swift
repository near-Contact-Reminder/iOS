import SwiftUI
import CoreData

struct ProfileEditView: View {
    @ObservedObject var profileEditViewModel: ProfileEditViewModel
    @StateObject var notificationViewModel = NotificationViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    let contactFrequencies = ["매일", "매주", "2주", "매달", "매분기", "6개월", "매년"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                NameSection(name: $profileEditViewModel.person.name)
                RelationshipSection(relationship: $profileEditViewModel.person.relationship)
                FrequencySection(frequency: $profileEditViewModel.person.frequency, options: contactFrequencies)
                            BirthdaySection(birthday: $profileEditViewModel.person.birthDay)
                            AnniversarySection(anniversary: $profileEditViewModel.person.anniversary)
                            MemoSection(memo: $profileEditViewModel.person.memo)
            }
        }
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .background(Color.white)
        .padding(.horizontal, 24)
        
    }
}

struct NameSection: View {
    @Binding var name: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(spacing: 0) {
                Text("이름")
                    .foregroundColor(Color.gray)
                    .font(Font.Pretendard.b2Medium())
                Text("*")
                    .foregroundColor(Color.blue01)
                    .font(Font.Pretendard.b2Medium())
            }
            Spacer()
            TextField("20자 내로 이름을 입력해주세요", text: $name)
                .font(Font.Pretendard.b2Medium())
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .padding(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray02, lineWidth: 1)
                )
                .cornerRadius(12)
                .onChange(of: name) {
                    if name.count > 20 {
                        name = String(name.prefix(20))
                    }
                }
        }.padding(.top, 48)
    }
}
    
struct RelationshipSection: View {
    @Binding var relationship: String?
    let options = ["친구", "가족", "지인"]
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("관계")
                .foregroundColor(.gray)
                .font(.Pretendard.b2Medium())
            Spacer()
            HStack(spacing: 48) {
                ForEach(options, id: \.self) { option in
                    HStack(spacing: 21)  {
                        Image(systemName: relationship == option ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(relationship == option ? Color.blue01 : Color.gray03)
                        
                        Text(option)
                            .font(.Pretendard.b2Medium())
                            .foregroundColor(.black)
                        }
                        .onTapGesture {
                            relationship = option
                    }.contentShape(Rectangle())
                    }
                }
            }
            .padding(.vertical,12)
    }
}

struct FrequencySection: View {
    @Binding var frequency: CheckInFrequency?
    let options: [String]

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("연락 주기")
                .foregroundColor(.gray)
                .font(.Pretendard.b2Medium())

            Spacer()

            Menu {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        frequency = CheckInFrequency(rawValue: option)
                    }) {
                        Text(option)
                            .foregroundColor(.black)
                            .font(Font.Pretendard.b2Medium())
                    }
                }
            } label: {
                HStack {
                    Text(frequency?.rawValue ?? "선택")
                        .foregroundColor(.black)
                        .font(Font.Pretendard.b2Medium())
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray02, lineWidth: 1)
                )
                .cornerRadius(12)
            }
        }
    }
}


struct BirthdaySection: View {
    @Binding var birthday: Date?
    @State private var isPickerVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                Text("생일")
                    .foregroundColor(.gray)
                    .font(.Pretendard.b2Medium())

                Spacer()

                Button {
                    isPickerVisible.toggle()
                } label: {
                    Text(birthday != nil ? formattedDate(birthday!) : "선택")
                        .font(.Pretendard.b2Medium())
                        .foregroundColor(birthday != nil ? .black : .gray02)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray02, lineWidth: 1)
                        )
                        .cornerRadius(12)
                }
            }

            if isPickerVisible {
                DatePicker(
                    "",
                    selection: Binding(
                        get: { birthday ?? Date() },
                        set: { birthday = $0 }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: isPickerVisible)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter.string(from: date)
    }
}

struct AnniversarySection: View {
    @Binding var anniversary: AnniversaryModel?
    @State private var isPickerVisible = false
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Label
            Text("기념일")
                .foregroundColor(.gray)
                .font(.Pretendard.b2Medium())

            // Title Input
            TextField("기념일 이름", text: Binding(
                get: { anniversary?.title ?? "" },
                set: { newValue in
                    if anniversary == nil {
                        anniversary = AnniversaryModel(title: newValue, Date: nil)
                    } else {
                        anniversary?.title = newValue
                    }
                }
            ))
            .focused($isTitleFocused)
            .font(.Pretendard.b2Medium())
            .padding(16)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray02, lineWidth: 1)
            )
            .cornerRadius(12)

            // 날짜 선택 버튼
            Button {
                isPickerVisible.toggle()
                isTitleFocused = false
            } label: {
                HStack {
                    Text(anniversary?.Date?.formattedYYYYMMDDWithDot() ?? "날짜 선택")
                        .font(.Pretendard.b2Medium())
                        .foregroundColor(anniversary?.Date != nil ? .black : .gray02)

                    Spacer()

                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray02, lineWidth: 1)
                )
            }

            // 피커
            if isPickerVisible {
                DatePicker(
                    "",
                    selection: Binding(
                        get: { anniversary?.Date ?? Date() },
                        set: { newValue in
                            if anniversary == nil {
                                anniversary = AnniversaryModel(title: "", Date: newValue)
                            } else {
                                anniversary?.Date = newValue
                            }
                        }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
            }
        }
    }
}
struct MemoSection: View {
    @Binding var memo: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("메모")
                .foregroundColor(.gray)
                .font(.Pretendard.b2Medium())

            ZStack(alignment: .topLeading) {
                if (memo ?? "").isEmpty {
                    Text("꼭 기억해야 할 내용을 기록해보세요. 예) 날생선 X, 작년에 생일에 키링 선물함 등")
                    .foregroundColor(.gray02)
                    .font(Font.Pretendard.b1Bold())
                    .padding(16)
                }

                TextEditor(text: Binding(
                    get: { memo ?? "" },
                    set: { memo = $0 }
                ))
                .font(.Pretendard.b2Medium())
                .padding(16)
                .frame(minHeight: 120)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray02, lineWidth: 1)
                )
                .cornerRadius(12)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .onChange(of: memo) { _ in
                    if let text = memo, text.count > 100 {
                        memo = String(text.prefix(100))
                    }
                }
            }

            HStack {
                Spacer()
                Text("\((memo ?? "").count)/100")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
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
            VStack(alignment: .leading) {
                if !title.isEmpty {
                    Text(title)
                        .font(.headline)
                }
                
                Button {
                    isPickerVisible.toggle()
                } label: {
                    HStack {
                        Text(date != nil ? formattedDate(date!) : "선택 안함")
                            .foregroundColor(date != nil ? .primary : .gray)
                    }
                }
                
                if isPickerVisible {
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
        
        private var dateRange: ClosedRange<Date> {
            let maxDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            return limitToPast ? Date.distantPast...maxDate : Date.distantPast...Date.distantFuture
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
            let dummyFriend = Friend(
                id: UUID(),
                name: "미리보기용",
                image: nil,
                imageURL: nil,
                source: .kakao,
                frequency: .monthly,
                remindCategory: .message,
                phoneNumber: "010-1234-5678",
                relationship: "동료",
                birthDay: Date(),
                anniversary: AnniversaryModel(title: "결혼기념일", Date: Date()),
                memo: "테스트 메모",
                nextContactAt: Date().addingTimeInterval(86400 * 30),
                lastContactAt: Date().addingTimeInterval(-86400 * 10),
                checkRate: 75,
                position: 0,
                fileName: "preview.jpg"
            )
            
            let dummyVM = ProfileEditViewModel(person: dummyFriend)
            
            return ProfileEditView(profileEditViewModel: dummyVM)
        }
    }
