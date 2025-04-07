import SwiftUI
import CoreData

struct ProfileEditView: View {
    
    @StateObject var profileEditViewModel = ProfileEditViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String = ""
    @State private var relationship: String = "친구"
    @State private var contactFrequency: String = "매주"
    @State private var birthday: Date? = nil  // Optional Date for birthday
    @State private var anniversaries: [(label: String, date: Date?)] = [("", nil)]
    @State private var memo: String = ""
    
    let contactFrequencies = ["매일", "매주", "2주", "매달", "매분기", "6개월","매년"]
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("이름")) {
                    TextField("이름 입력", text: $name)
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
                
                Section(header: Text("생일")) {
                    // Use nil-coalescing operator to provide a default value if birthday is nil
                    DatePicker("날짜 선택", selection: Binding(
                        get: { birthday ?? Date() },
                        set: { birthday = $0 }
                    ), displayedComponents: .date)
                }
                
                Section(header: Text("기념일")) {
                    ForEach(anniversaries.indices, id: \.self) { index in
                        HStack {
                            TextField("레이블", text: $anniversaries[index].label)
                            // Use nil-coalescing operator to provide a default value if anniversaries[index].date is nil
                            DatePicker("날짜 선택", selection: Binding(
                                get: { anniversaries[index].date ?? Date() },
                                set: { anniversaries[index].date = $0 }
                            ), displayedComponents: .date)
                        }
                    }
                    Button(action: {
                        // Append a new anniversary with default date as Date()
                        anniversaries.append(("", nil))
                    }) {
                        Label("일정 추가하기", systemImage: "plus")
                    }
                }
                
                Section(header: Text("메모")) {
                    TextEditor(text: $memo)
                        .frame(height: 100)
                }
            }
            
            Button(action: {
                profileEditViewModel.addNewPerson(name: name, relationship: relationship, birthday: birthday, anniversary: anniversaries.first?.date, reminderInterval: contactFrequency, memo: memo)
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

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        // Replace with valid PersonEntity for preview
        ProfileEditView()
    }
}
