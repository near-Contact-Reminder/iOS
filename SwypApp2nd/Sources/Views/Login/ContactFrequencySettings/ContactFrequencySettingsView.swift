import SwiftUI

struct ContactFrequencySettingsView: View {
    @ObservedObject var viewModel: ContactFrequencySettingsViewModel
    @ObservedObject var notificationViewModel: NotificationViewModel

    @State private var selectedPerson: Friend?
    @State private var showFrequencyPicker: Bool = false
    
    let back: () -> Void
    let complete: ([Friend]) -> Void

    var body: some View {
        Spacer()
            .frame(height: 12)
        
        VStack(alignment: .leading, spacing: 24) {
            // 헤더 텍스트
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("챙김 주기 설정하기")
                        .font(.Pretendard.b1Bold())
                    Spacer()
                    Text("2 / 2")
                        .font(.Pretendard.captionBold())
                        .foregroundColor(.gray02)
                }

                Image("img_100_character_default")
                    .frame(height: 80)

                Text("얼마나 자주\n챙기고 싶으세요?")
                    .font(.Pretendard.h1Bold())
                Text("사람별로 챙기고 싶은 주기를 설정해주세요.")
                    .font(.Pretendard.b2Bold())
                    .foregroundColor(.gray02)
            }
            .padding(.horizontal, 24)

            // 한 번에 설정
            Button(action: {
                viewModel.toggleUnifiedFrequency(!viewModel.isUnified)
            }) {
                HStack(spacing: 8) {
                    Text("한번에 설정")
                        .font(.Pretendard.b2Medium())
                        .foregroundColor(.gray02)
                    Image(
                        systemName: viewModel.isUnified ? "checkmark.square.fill" : "square"
                    )
                    .foregroundColor(
                        viewModel.isUnified ? .blue01 : .gray02
                    )
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            // 공통 주기 설정 드롭다운
            if viewModel.isUnified {
                Button(action: {
                    showFrequencyPicker = true
                }) {
                    HStack {
                        Text(
                            viewModel.unifiedFrequency?.rawValue ?? "주기 선택"
                        )
                        .font(.Pretendard.b2Medium())
                        .foregroundColor(
                            viewModel.unifiedFrequency == nil ? .gray02 : .black
                        )

                        Spacer()

                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray02)
                    }
                    .padding()
                    .padding(.horizontal, 8)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 24)
            }

            // 사람 리스트
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(viewModel.people) { person in
                        FrequencyRow(
                            person: person,
                            isUnified: viewModel.isUnified
                        ) {
                            selectedPerson = person
                            showFrequencyPicker = true
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            // 하단 버튼
            HStack(spacing: 12) {
                Button(action: back) {
                    Text("이전")
                        .font(.body.bold())
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.white)
                        .foregroundStyle(Color.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    Color.gray.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                }

                Button{
                    // 카카오는 이미지 저장 후 BackEnd 서버에 전송
                    viewModel.downloadKakaoImageData { friendsWithImages in
                        DispatchQueue.main.async {
                            viewModel.uploadAllFriendsToServer(viewModel.people) {
                                UserSession.shared.user?.friends = viewModel.people
                                notificationViewModel.scheduleAnbu(people: UserSession.shared.user?.friends ?? [])
                                complete(viewModel.people)
                            }
                        }
                        
                    }
                }
                label: {
                    Text("완료")
                        .font(.body.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            viewModel.canComplete ? Color.blue01 : Color.gray01
                        )
                        .cornerRadius(12)
                }
                .disabled(!viewModel.canComplete)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showFrequencyPicker) {
            FrequencyPickerView(
                selected: viewModel.isUnified ? viewModel.unifiedFrequency : selectedPerson?.frequency,
                onSelect: { freq in
                    if viewModel.isUnified {
                        viewModel.applyUnifiedFrequency(freq)
                    } else if let person = selectedPerson {
                        viewModel.updateFrequency(for: person, to: freq)
                    }
                    showFrequencyPicker = false
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - 사람별 주기설정 셀
struct FrequencyRow: View {
    let person: Friend
    let isUnified: Bool
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if person.source == .kakao {
                Image("img_32_kakao_square")
                    .resizable()
                    .frame(width: 32, height: 32)
            } else {
                Image("img_32_contact_square")
                    .resizable()
                    .frame(width: 32, height: 32)
            }
            
            Text(person.name)
                .font(.Pretendard.b2Medium())
            Spacer()
            Button(action: { if !isUnified { onSelect() } }
            ) {
                Text(person.frequency?.rawValue ?? "주기 선택")
                    .font(.Pretendard.b2Medium())
                Image(systemName: "chevron.down")
            }
            .foregroundStyle(Color.gray01)
            
        }
        .padding()
        .padding(.horizontal, 8)
        .background(Color.bg02)
        .cornerRadius(12)
    }
}

// MARK: - 주기 설정 바텀 시트
struct FrequencyPickerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var tempSelected: CheckInFrequency?
    
    let selected: CheckInFrequency?
    let onSelect: (CheckInFrequency) -> Void

    var body: some View {
        
        VStack(alignment: .leading) {

            Text("주기 설정")
                .font(.headline)
                .padding(.top, 16)
                .padding(.leading, 16)
            
            if let selected = tempSelected {
                let today = Date()
                let nextDate = today.nextCheckInDate(for: selected)
                let nextDateDayOfTheWeek = today.nextCheckInDateDayOfTheWeek(for: selected)
                
                HStack {
                    Text("\(selected.rawValue) ")
                        .font(.body)
                        .foregroundColor(.gray02)

                    Text(nextDateDayOfTheWeek)
                        .font(.body)
                        .foregroundColor(.blue01)

                    Spacer()

                    Text("다음 주기: \(nextDate)")
                        .font(.caption)
                        .foregroundColor(.gray02)
                }
                .padding()
                .background(Color.bg01)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 8)
            }
            
     
            VStack(spacing: 0) {
                ForEach(CheckInFrequency.allCases.dropFirst()) { frequency in
                    Button(action: {
                        tempSelected = frequency
                    }) {
                        HStack {
                            Text(frequency.rawValue)
                                .font(.Pretendard.b2Medium())
                                .foregroundColor(.black)
                            Spacer()
                            if frequency == tempSelected {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue01)
                            }
                        }
                        .padding(.horizontal, 24)
                        .frame(height: 44)
                    }
                }
            }
            .listStyle(.inset)
            .background(Color.white)
            
            // 하단 버튼
            HStack(spacing: 12) {
                Button(action: {
                    dismiss()
                }) {
                    Text("취소")
                        .font(.body.bold())
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    Color.gray.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                }

                Button(action: {
                    if let selected = tempSelected {
                        onSelect(selected)
                    }
                    dismiss()
                }) {
                    Text("완료")
                        .font(.body.bold())
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.blue01)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 24)
        }
        .background(Color.white)
        .cornerRadius(20)
    }
}

//#Preview {
//    let viewModel: ContactFrequencySettingsViewModel = {
//        let vm = ContactFrequencySettingsViewModel()
//        vm.people = [
//            Friend(id: UUID(), name: "정종원", image: nil, source: ContactSource.kakao, frequency: CheckInFrequency.none),
//            Friend(id: UUID(), name: "정종원", image: nil, source: ContactSource.kakao, frequency: CheckInFrequency.none),
//            Friend(id: UUID(), name: "정종원", image: nil, source: ContactSource.kakao, frequency: CheckInFrequency.none),
//            Friend(id: UUID(), name: "정종원", image: nil, source: ContactSource.phone, frequency: CheckInFrequency.none),
//            Friend(id: UUID(), name: "정종원", image: nil, source: ContactSource.phone, frequency: CheckInFrequency.none),
//            Friend(id: UUID(), name: "정종원", image: nil, source: ContactSource.phone, frequency: CheckInFrequency.none)
//        ]
//        return vm
//    }()
//    ContactFrequencySettingsView(
//        viewModel: viewModel,
//        back: { print("이전") },
//        complete: { print("완료") }
//    )
//}
