import SwiftUI

struct ContactFrequencySettingsView: View {
    @ObservedObject var viewModel: ContactFrequencySettingsViewModel
    @ObservedObject var inboxViewModel: InboxViewModel

    @State private var selectedPerson: Friend?
    @State private var showFrequencyPicker: Bool = false
    @State private var pickerSelectedFrequency: CheckInFrequency? = nil
    let back: () -> Void
    let complete: ([Friend]) -> Void
    @State var isChecked: Bool = false

    var body: some View {
        Spacer()
            .frame(height: 12)

        VStack(alignment: .leading, spacing: 24) {
            // 헤더 텍스트
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("챙김 주기 설정하기")
                        .modifier(Font.Pretendard.b1BoldStyle())

                    Spacer()

                    Text("2 / 2")
                        .modifier(Font.Pretendard.captionBoldStyle())
                        .foregroundColor(.gray02)
                }

                Spacer()
                    .frame( height: 20)

                Image("img_100_character_default")
                    .frame(height: 80)

                Text("얼마나 자주\n챙기고 싶으세요?")
                    .modifier(Font.Pretendard.h1BoldStyle())
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                Text("사람별로 챙기고 싶은 주기를 설정해주세요.")
                    .modifier(Font.Pretendard.b1MediumStyle())
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.gray02)

            }
            .padding(.horizontal, 20)

            // 한 번에 설정
            HStack {
                Spacer()
                Button(action: {
                    let newValue = !viewModel.isUnified
                    viewModel.toggleUnifiedFrequency(newValue)
                    isChecked = newValue
                    if newValue {
                        pickerSelectedFrequency = viewModel.unifiedFrequency
                    }
                }) {
                    HStack(spacing: 12) {
                        Text("한번에 설정")
                            .modifier(Font.Pretendard.b1MediumStyle())
                            .foregroundColor(.gray02)
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(
                                    isChecked ? Color.blue01 : Color.gray03,
                                    lineWidth: 2
                                )
                                .frame(width: 24, height: 24)
                                .background(
                                    isChecked ? Color.blue01 : Color.gray03
                                )
                                .cornerRadius(6)
                            Image("icon_check_white")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            // 공통 주기 설정 드롭다운
            if viewModel.isUnified {
                Button(action: {
                    if viewModel.unifiedFrequency == nil {
                        viewModel.applyUnifiedFrequency(.weekly)
                        pickerSelectedFrequency = .weekly
                    } else {
                        pickerSelectedFrequency = viewModel.unifiedFrequency
                    }
                    showFrequencyPicker = true
                }) {
                    HStack {
                        Text(
                            viewModel.unifiedFrequency?.rawValue ?? "주기 선택"
                        )
                        .font(.Pretendard.b1Medium())
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
                }
                .frame(height: 52)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 20)
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
                            pickerSelectedFrequency = person.frequency
                            showFrequencyPicker = true
                            AnalyticsManager.shared.setCareFrequencyLogAnalytics()
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            // 하단 버튼
            HStack(spacing: 12) {
                Button{
                    back()
                    isChecked = false
                    viewModel.toggleUnifiedFrequency(false)
                } label: {
                    Text("이전")
                        .modifier(Font.Pretendard.b1BoldStyle())
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
                    // 카카오는 이미지 저장 후 BackEnd 서버에 전송 (스펙 아웃)
//                    viewModel.downloadKakaoImageData { friendsWithImages in
//                    }
                    DispatchQueue.main.async {
                        viewModel.uploadAllFriendsToServer(viewModel.people) {
                            UserSession.shared.user?.friends = viewModel.people
                            AnalyticsManager.shared.setProfileCountBucket(viewModel.people.count)
                            AnalyticsManager.shared.completeButtonLogAnalytics()
                            self.isChecked = false // 완료 시 체크박스 비활성화
                            self.showFrequencyPicker = false
                            viewModel.toggleUnifiedFrequency(false) // ViewModel 상태도 비활성화
                            complete(viewModel.people)
                        }
                    }
                }
                label: {
                    Text("완료")
                        .modifier(Font.Pretendard.b1BoldStyle())
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
        .sheet(isPresented: $showFrequencyPicker, onDismiss: {
            pickerSelectedFrequency = nil
        }) {
            FrequencyPickerView(
                selected: pickerSelectedFrequency,
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
            .presentationCornerRadius(20)
        }
        .onAppear {
            isChecked = viewModel.isUnified
            AnalyticsManager.shared.trackContactFrequencySettingsViewLogAnalytics()
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
                .modifier(Font.Pretendard.b2MediumStyle())
            Spacer()
            Button(action: { if !isUnified { onSelect() } }
            ) {
                Text(person.frequency?.rawValue ?? "주기 선택")
                    .modifier(Font.Pretendard.b2MediumStyle())
                Image(systemName: "chevron.down")
            }
            .foregroundStyle(Color.gray01)

        }
        .padding()
        .padding(.horizontal, 4)
        .background(Color.bg02)
        .cornerRadius(12)
    }
}

// MARK: - 주기 설정 바텀 시트
struct FrequencyPickerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var tempSelected: CheckInFrequency? = .weekly

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
                    Divider()
                        .foregroundColor(.gray02)
                        .frame(height: 20)
                    Text("다음 주기: \(nextDate)")
                        .font(.caption)
                        .foregroundColor(.gray02)
                }
                .padding()
                .background(Color.bg02)
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
                                Image("icon_check_blue")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 14, height: 14)
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
                        .frame(height: 56)
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
                    } else if let selected = selected {
                        onSelect(selected)
                    }
                }) {
                    Text("완료")
                        .font(.body.bold())
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue01)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 24)
        }
        .background(Color.white)
        .cornerRadius(20)
        .onAppear {
            tempSelected = selected
        }
    }
}

#Preview {
    ContactFrequencySettingsView(
        viewModel: ContactFrequencySettingsViewModel(),
        inboxViewModel: InboxViewModel(),
        back: {}) { _ in

        }
}

#Preview("FrequencyPickerView") {
    FrequencyPickerView(selected: CheckInFrequency.none) { _ in
        print("test")
    }
}
