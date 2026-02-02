import SwiftUI

struct ProfileEditView: View {
    @ObservedObject var profileEditViewModel: ProfileEditViewModel
    @StateObject var notificationViewModel = NotificationViewModel()
    @StateObject var keyboard = KeyboardObserver()
    @FocusState private var isMemoFocused: Bool
    @State private var nameError: String?
    @State private var anniversaryError: String?

    let contactFrequencies = ["매일", "매주", "2주", "매달", "매분기", "6개월", "매년"]
    let onComplete: () -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    NameSection(
                        name: $profileEditViewModel.person.name,
                        errorText: nameError
                    )
                    RelationshipSection(
                        relationship: $profileEditViewModel.person.relationship
                    )
                    FrequencySection(
                        frequency: $profileEditViewModel.person.frequency,
                        options: contactFrequencies
                    )
                    BirthdaySection(birthday: $profileEditViewModel.person.birthDay)
                    AnniversarySection(
                        anniversary: $profileEditViewModel.person.anniversary,
                        errorText: anniversaryError
                    )
                    MemoSection(
                        memo: $profileEditViewModel.person.memo,
                        isFocused: $isMemoFocused
                    )
                    .id("memoSection")
                }
            }
            .onChange(of: isMemoFocused) { _, focused in
                if focused {
                    withAnimation {
                        proxy.scrollTo("memoSection", anchor: .bottom)
                    }
                }
            }
        }
        .contentShape(Rectangle())
           .onTapGesture {
               isMemoFocused = false
           }
        .onAppear {
            AnalyticsManager.shared.trackProfileEditViewLogAnalytics()
        }
        .toolbar{
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    onComplete() // 뒤로 가기 혹은 닫기
                }) {
                    Image.Icon.backBlack
                        .foregroundColor(.black)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("완료") {
                    let errors = profileEditViewModel.validateInputs()
                    nameError = errors?.nameError
                    anniversaryError = errors?.anniversaryError
                    
                    guard errors == nil else { return }
                    
                    profileEditViewModel
                        .updateFriendDetail(
                            friendId: profileEditViewModel.person.id
                        ) {
                            onComplete()
                        }
                }
                .foregroundColor(.black)
                .font(Font.Pretendard.b1Bold())
            }
        }
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(Color.white)
        .padding(.horizontal, 24)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: keyboard.keyboardHeight)
        }
    }
}

struct NameSection: View {
    @Binding var name: String
    var errorText: String?
    
    var body: some View {
        VStack(alignment: .leading) {
        HStack(alignment: .center, spacing: 12) {
                HStack(spacing: 0) {
                    Text("이름")
                        .foregroundColor(Color.gray01)
                        .modifier(Font.Pretendard.b2MediumStyle())
                    Text("*")
                        .foregroundColor(Color.blue01)
                        .modifier(Font.Pretendard.b2MediumStyle())
                }
                .frame(width: 60, alignment: .leading)
                TextField("20자 내로 이름을 입력해주세요", text: $name)
                    .modifier(Font.Pretendard.b2MediumStyle())
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .padding(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray03, lineWidth: 1)
                    )
                    .onChange(of: name) {
                        if name.count > 20 {
                            name = String(name.prefix(20))
                        }
                    }
                
            }
        .padding(.top, 24)
        if let errorText, !errorText.isEmpty {
            Text(errorText)
                .foregroundColor(.red)
                .font(.caption)
                .padding(.leading, 72)
            }
        }
    }
}
    
struct RelationshipSection: View {
    @Binding var relationship: String?
    let options = ["친구", "가족", "지인"]
    
    var body: some View {
            HStack(alignment: .center, spacing: 0) {
                Text("관계")
                    .foregroundColor(Color.gray01)
                    .modifier(Font.Pretendard.b2MediumStyle())
                    .frame(width: 60, alignment: .leading)
                
                Spacer(minLength: 20)
                
                HStack(spacing: 0){
                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            relationship = rawValue(for: option)
                        }) {
                            HStack(spacing: 6) {
                                (displayLabel(for: relationship) == option ? Image.Icon.radio24Blue : Image.Icon.radio24Gray)
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Text(option)
                                    .modifier(Font.Pretendard.b2MediumStyle())
                                    .foregroundColor(.black)
                            }
                        }
                        if option != options.last {
                            Spacer()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)
    }
    
    private func displayLabel(for rawValue: String?) -> String? {
        switch rawValue {
        case "FRIEND": return "친구"
        case "FAMILY": return "가족"
        case "ACQUAINTANCE": return "지인"
        default: return nil
        }
    }

    private func rawValue(for displayLabel: String) -> String {
        switch displayLabel {
        case "친구": return "FRIEND"
        case "가족": return "FAMILY"
        case "지인": return "ACQUAINTANCE"
        default: return "ACQUAINTANCE"
        }
    }
}

struct FrequencySection: View {
        @Binding var frequency: CheckInFrequency?
        let options: [String]
        
        var body: some View {
            HStack(alignment: .center) {
                Text("연락 주기")
                    .foregroundColor(Color.gray01)
                    .modifier(Font.Pretendard.b2MediumStyle())
                    .frame(width: 60, alignment: .leading)
                
                Spacer()
                
                Menu {
                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            frequency = CheckInFrequency(rawValue: option)
                        }) {
                            Text(option)
                                .foregroundColor(.black)
                                .modifier(Font.Pretendard.b2MediumStyle())
                        }
                    }
                } label: {
                    HStack {
                        Text(frequency?.rawValue ?? "선택")
                            .foregroundColor(.black)
                            .modifier(Font.Pretendard.b2MediumStyle())
                        Spacer()
                        Image.Icon.downBlack
                    }
                    .padding(16)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray03, lineWidth: 1)
                    )
                }
            }
        }
    }
    
    
    struct BirthdaySection: View {
        @Binding var birthday: Date?
        @State private var isPickerVisible = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("생일")
                        .foregroundColor(Color.gray01)
                        .modifier(Font.Pretendard.b2MediumStyle())
                        .frame(width: 60, alignment: .leading)
                    
                    Spacer()
                    
                    Button {
                        isPickerVisible.toggle()
                    } label: {
                        HStack {
                            Text(birthday != nil ? formattedDate(birthday!) : "선택")
                                .modifier(Font.Pretendard.b2MediumStyle())
                                .foregroundColor(birthday != nil ? .black : .gray02)
                            
                            Spacer()
                            Image.Icon.downBlack
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray03, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                if isPickerVisible {
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { birthday ?? Date() },
                            set: { birthday = $0.startOfDayInKorea() }
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
            formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
            formatter.dateFormat = "yyyy년 M월 d일"
            return formatter.string(from: date)
        }
    }

    struct AnniversarySection: View {
        @Binding var anniversary: AnniversaryModel?
        @State private var isPickerVisible = false
        @FocusState private var isTitleFocused: Bool
        var errorText: String?
        
        private var anniversaryTitleBinding: Binding<String> {
            Binding(
                get: { anniversary?.title ?? "" },
                set: { newValue in
                    if anniversary == nil {
                        anniversary = AnniversaryModel(title: newValue, Date: nil)
                    } else {
                        anniversary?.title = newValue
                    }
                }
            )
        }

        private var anniversaryDateBinding: Binding<Date> {
            Binding(
                get: { anniversary?.Date ?? Date() },
                set: { newValue in
                    let dateAtStart = newValue.startOfDayInKorea()
                    if anniversary == nil {
                        anniversary = AnniversaryModel(title: "", Date: dateAtStart)
                    } else {
                        anniversary?.Date = dateAtStart
                    }
                }
            )
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("기념일")
                        .foregroundColor(Color.gray01)
                        .modifier(Font.Pretendard.b2MediumStyle())
                        .frame(width: 60, alignment: .leading)
                    Spacer()
                    Button{
                        // anniversary 추가
                    } label: {
                        Text("추가하기")
                            .modifier(Font.Pretendard.b2MediumStyle())
                            .foregroundColor(Color.blue01)
                    }
                }.padding(.vertical,8)
                
                HStack {
                    Text("이름")
                        .foregroundColor(Color.gray01)
                        .modifier(Font.Pretendard.b2MediumStyle())
                        .frame(width: 60, alignment: .leading)
                    
                    Spacer()
                    TextField("기념일 이름", text: anniversaryTitleBinding)
                    .focused($isTitleFocused)
                    .font(.Pretendard.b2Medium())
                    .padding(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray03, lineWidth: 1)
                    )
                }
                HStack{
                    Text("날짜")
                        .foregroundColor(Color.gray01)
                        .modifier(Font.Pretendard.b2MediumStyle())
                        .frame(width: 60, alignment: .leading)
                    
                    Button {
                        isPickerVisible.toggle()
                        isTitleFocused = false
                    } label: {
                        HStack {
                            Text(anniversary?.Date?.formattedYYYYMMDDWithDot() ?? "날짜 선택")
                                .modifier(Font.Pretendard.b2MediumStyle())
                                .foregroundColor(anniversary?.Date != nil ? .black : .gray02)
                            
                            Spacer()
                            Image.Icon.downBlack
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray03, lineWidth: 1)
                        )
                    }
                }
                // 피커
                if isPickerVisible {
                    DatePicker("", selection: anniversaryDateBinding, displayedComponents: .date)
                        .datePickerStyle(.wheel)
                }
                
                Button(action: {
                    withAnimation {
                        // TODO 일단 지금 있는 거만 clear out
                        anniversary = nil
                        isPickerVisible = false
                    }
                }) {
                    Text("삭제하기")
                        .modifier(Font.Pretendard.b2MediumStyle())
                        .underline()
                        .foregroundColor(Color.gray01)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                
                if let errorText, !errorText.isEmpty {
                    Text(errorText)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.leading, 4)
                        .padding(.top, 4)
                }
            }
        }
    }

    struct MemoSection: View {
        @Binding var memo: String?
        @FocusState.Binding var isFocused: Bool
        
        var body: some View {
            HStack(alignment: .top) {
                Text("메모")
                    .foregroundColor(Color.gray01)
                    .modifier(Font.Pretendard.b2MediumStyle())
                    .frame(width: 60, alignment: .leading)
                
                ZStack(alignment: .bottomTrailing) { // 글자 수를 오른쪽 아래에 배치
                    
                    ZStack(alignment: .topLeading) {
                        if (memo ?? "").isEmpty {
                            Text("꼭 기억해야 할 내용을 기록해보세요.\n예) 날생선 X, 작년 생일에 키링 선물함 등")
                                .foregroundColor(Color.gray02)
                                .modifier(Font.Pretendard.b2MediumStyle())
                                .padding(12)
                                .allowsHitTesting(false)
                        }
                        
                        TextEditor(text: Binding(
                            get: { memo ?? "" },
                            set: { newValue in
                                if newValue.count <= 100 {
                                    memo = newValue
                                }
                            }
                        ))
                        .focused($isFocused)
                        .font(.Pretendard.b2Medium())
                        .padding(8)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                    }
                    .frame(minHeight: 160)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray03, lineWidth: 1)
                    )

                    Text("\((memo ?? "").count)/100")
                        .font(.caption)
                        .foregroundColor(Color.gray01)
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
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
                        .modifier(Font.Pretendard.b1MediumStyle())
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
                            set: { date = $0.startOfDayInKorea() }
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
            let maxDate = Calendar.current.date(
                byAdding: .day,
                value: -1,
                to: Date()
            )!
            return limitToPast ? Date.distantPast...maxDate : Date.distantPast...Date.distantFuture
        }
        
        private func formattedDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
            formatter.dateFormat = "yyyy년 M월 d일"
            return formatter.string(from: date)
        }
    }
    
    /// 키보드 높이를 관찰해 하단 인셋에 반영
    final class KeyboardObserver: ObservableObject {
        @Published var keyboardHeight: CGFloat = 0
        private var willShow: NSObjectProtocol?
        private var willHide: NSObjectProtocol?
        
        init() {
            willShow = NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardWillShowNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard
                    let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
                else { return }
                self?.keyboardHeight = frame.height
            }
            
            willHide = NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardWillHideNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.keyboardHeight = 0
            }
        }
        
        deinit {
            if let willShow { NotificationCenter.default.removeObserver(willShow) }
            if let willHide { NotificationCenter.default.removeObserver(willHide) }
        }
    }
    
    // MARK: - Preview
    struct ProfileEditView_Previews: PreviewProvider {
        static var previews: some View {
            let mockFriend = Friend(
                id: UUID(),
                name: "",
                image: nil,
                imageURL: nil,
                source: .phone,
                frequency: .weekly,
                remindCategory: .message,
                relationship: "FRIEND", birthDay: Date(), anniversary: AnniversaryModel(title: "만난 날", Date: Date()),
                memo: "",
                nextContactAt: Date(),
                lastContactAt: Date(),
                checkRate: 50,
                position: 0
            )
            
            let vm = ProfileEditViewModel(person: mockFriend)
            
            NavigationStack {
                ProfileEditView(profileEditViewModel: vm) { }
            }
            .previewDevice("iPhone 15")
        }
    }
