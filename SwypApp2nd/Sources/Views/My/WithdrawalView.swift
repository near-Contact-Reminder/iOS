import SwiftUI

struct WithdrawalView: View {
    @Binding var path: [AppRoute]
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedReason: String = ""
    @State private var customReason: String = ""
    @State private var showConfirmAlert = false
    @FocusState private var isCustomReasonFocused: Bool
    var user = UserSession.shared.user!
    
    var isValidCustomReason: Bool {
        selectedReason != "기타" || (customReason.count >= 1 && customReason.count <= 200)
    }
        
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            WithdrawalHeaderView()
                
            Text("\(user.name)님, \n떠나는 이유를 알려주시면 \n큰 도움이 될 거예요.")
                .font(Font.Pretendard.h1Medium(size: 24))
                .lineSpacing(8)
                .padding(.top, 42)
            
            Text("소중한 의견을 받아 \n더 나은 서비스를 만들어갈게요.")
                .font(Font.Pretendard.b1Medium())
                .foregroundColor(.gray)
                .padding(.bottom, 42)
            
            WithdrawalReasonListView(
                selectedReason: $selectedReason,
                isCustomReasonFocused: _isCustomReasonFocused
            )
            
            if selectedReason == "기타" {
                CustomReasonInputView(
                    customReason: $customReason,
                    isCustomReasonFocused: _isCustomReasonFocused
                )
            }
            
            Spacer()
            
            WithdrawalActionButtonsView(
                isValid: isValidCustomReason,
                onWithdraw: { showConfirmAlert = true },
                onCancel: { presentationMode.wrappedValue.dismiss() }
            )
        }
        .padding()
}

struct WithdrawalHeaderView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        HStack {
            Text("탈퇴하기")
                .font(Font.Pretendard.b1Bold())
            Spacer()
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .frame(width: 32, height: 32, alignment: .trailing)
                    .foregroundColor(Color.black)
            }
        }
    }
}

struct WithdrawalReasonListView: View {
    @Binding var selectedReason: String
    @FocusState var isCustomReasonFocused: Bool

    let reasons = [
        "자주 이용하지 않아요",
        "신규 계정으로 가입할래요",
        "개인정보가 우려돼요",
        "서비스가 불편해요",
        "기타"
    ]

    var body: some View {
        ForEach(reasons, id: \.self) { reason in
            HStack {
                Image(systemName: selectedReason == reason ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(selectedReason == reason ? Color.blue01 : Color.gray03)
                Text(reason)
                Spacer()
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .onTapGesture {
                selectedReason = reason
                if reason == "기타" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isCustomReasonFocused = true
                    }
                }
            }
        }
    }
}
    
struct CustomReasonInputView: View {
    @Binding var customReason: String
    @FocusState var isCustomReasonFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        customReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? Color.gray03 : Color.blue01,
                        lineWidth: 1
                    )
                    .frame(minHeight: 100)

                if customReason.isEmpty {
                    Text("편하게 의견을 남겨주세요.")
                        .font(Font.Pretendard.b1Medium())
                        .foregroundColor(Color.gray02)
                        .padding(.leading, 14)
                        .padding(.top, 16)
                        .zIndex(1)
                }

                VStack {
                    TextEditor(text: Binding(
                        get: { String(customReason.prefix(200)) },
                        set: { customReason = String($0.prefix(200)) }
                    ))
                    .padding(12)
                    .frame(minHeight: 100)
                    .background(Color.clear)
                    .focused($isCustomReasonFocused)

                    HStack {
                        Spacer()
                        Text("\(customReason.count)/200")
                            .font(.caption)
                            .foregroundColor(customReason.count >= 200 ? .red : .gray)
                            .padding(.trailing, 12)
                            .padding(.bottom, 4)
                    }
                }
            }

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
}

struct WithdrawalActionButtonsView: View {
    var isValid: Bool
    var onWithdraw: () -> Void
    var onCancel: () -> Void

    
    var body: some View {
        HStack {
            Button(action: onCancel) {
                Text("그만두기")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .font(Font.Pretendard.b1Bold())
                    .foregroundColor(.white)
                    .background(Color.blue01)
                    .cornerRadius(10)
            }

            Button(action: onWithdraw) {
                Text("탈퇴하기")
                    .font(Font.Pretendard.b1Bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.clear)
                    .foregroundColor(isValid ? Color.black : Color.gray)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isValid ? Color.black : Color.gray, lineWidth: 1)
                    )
                    .cornerRadius(10)
            }
            .disabled(!isValid)
        }
    }
}


struct WithdrawalView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            previewForDevice("iPhone 13 mini")
            previewForDevice("iPhone 16")
            previewForDevice("iPhone 16 Pro")
            previewForDevice("iPhone 16 Pro Max")
        }
    }
    
    static func previewForDevice(_ deviceName: String) -> some View {
        
        let fakeFriends = [
            Friend(
                id: UUID(), name: "정종원1", image: nil, imageURL: nil,
                source: .kakao, frequency: CheckInFrequency.none, remindCategory: .message,
                nextContactAt: Date(), lastContactAt: Date().addingTimeInterval(-86400),
                checkRate: 20, position: 0
            )
        ]
        
        UserSession.shared.user = User(
            id: "preview", name: "프리뷰",
            friends: fakeFriends,
            loginType: .kakao,
            serverAccessToken: "token",
            serverRefreshToken: "refresh"
        )
        
        return MyProfileWrapper()
            .previewDevice(PreviewDevice(rawValue: deviceName))
            .previewDisplayName(deviceName)
    }
    
    
    struct MyProfileWrapper: View {
        @State var path: [AppRoute] = [.my]
        
        var body: some View {
            WithdrawalView(path: $path)
        }
        
    }
}
}
