import SwiftUI

struct WithdrawalView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedReason: String = ""
    @State private var customReason: String = ""
    @FocusState private var isCustomReasonFocused: Bool

    let reasons = [
        "자주 이용하지 않아요",
        "신규 계정으로 가입할래요",
        "개인정보가 우려돼요",
        "서비스가 불편해요",
        "기타"
    ]

    var isValidCustomReason: Bool {
        selectedReason != "기타" || (customReason.count >= 1 && customReason.count <= 200)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 상단 헤더
            HStack {
                Text("탈퇴하기")
                    .font(.headline)
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                }
            }
            
            Spacer()
            // TODO 사람 이름 가져오기
            Text("김민지님, \n떠나는 이유를 알려주시면 \n큰 도움이 될 거예요.")
                .font(.title3)
                .fontWeight(.semibold)

            Text("소중한 의견을 받아 \n더 나은 서비스를 만들어갈게요.")
                .font(.footnote)
                .foregroundColor(.gray)

            // 탈퇴 사유 선택
            ForEach(reasons, id: \.self) { reason in
                HStack {
                    Image(systemName: selectedReason == reason ? "largecircle.fill.circle" : "circle")
                        .foregroundColor(.black)
                    Text(reason)
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedReason = reason
                    if reason == "기타" {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isCustomReasonFocused = true // 자동 포커스
                        }
                    }
                }
            }

            if selectedReason == "기타" {
                VStack(alignment: .leading, spacing: 5) {
                    ZStack(alignment: .topLeading) {
                        if customReason.isEmpty {
                            Text("탈퇴 사유를 적어주세요")
                                .foregroundColor(.gray)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 10)
                        }

                        TextEditor(text: Binding(
                            get: {
                                String(customReason.prefix(200))
                            },
                            set: {
                                customReason = String($0.prefix(200))
                            })
                        )
                        .frame(minHeight: 100)
                        .padding(6)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .focused($isCustomReasonFocused)
                    }

                    // 글자 수 표시
                    HStack {
                        Spacer()
                        Text("\(customReason.count)/200자")
                            .font(.caption)
                            .foregroundColor(customReason.count >= 200 ? .red : .gray)
                    }

                    // 벨리데이션 문구
                    if customReason.count < 1 {
                        Text("1글자 이상 입력해주세요.")
                            .foregroundColor(.red)
                            .font(.caption)
                    } else if customReason.count >= 200 {
                        Text("200자 이상 작성할 수 없어요.")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }

            Spacer()

            // 버튼 영역
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("더 써볼래요")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black))
                }

                Button(action: {
                    submitWithdrawal()
                }) {
                    Text("탈퇴하기")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValidCustomReason ? Color.black : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!isValidCustomReason)
            }
        }
        .padding()
    }

    private func submitWithdrawal() {
        let reason = selectedReason == "기타" ? customReason : selectedReason
        guard !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("탈퇴 사유 입력 필요")
            return
        }

        print("탈퇴 사유:", reason)
        // 실제 탈퇴 처리 로직
    }
}

struct WithdrawalView_Previews: PreviewProvider {
    static var previews: some View {
        WithdrawalView()
    }
}
