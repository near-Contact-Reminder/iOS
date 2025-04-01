import SwiftUI
import Combine
import WebKit

public struct TermsView: View {
    @ObservedObject var viewModel = TermsViewModel()
    
    // 약관 상세를 보여주기 위한 상태 관리
    /// 약관 상세 모달 Bool
    @State private var showingDetail = false
    /// 약관 상세 타이틀
    @State private var detailTitle = ""
    /// 약관 상세 웹 URL
    @State private var detailURLString = ""
    
    let completion: () -> Void

    public var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.secondary)
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            Text("서비스 약관 동의")
                .font(.headline)
                .padding(.top, 16)

            VStack(spacing: 12) {
                agreementRow(
                    isChecked: .constant(viewModel.isAllAgreed),
                    title: "약관 전체 동의",
                    isBold: true,
                    action: viewModel.toggleAllAgreed
                )
                agreementRow(
                    isChecked: $viewModel.isServiceTermsAgreed,
                    title: "서비스 이용 약관 상세",
                    showDetail: true,
                    detailURLString: "https://www.naver.com/"
                )
                agreementRow(
                    isChecked: $viewModel.isPersonalInfoTermsAgreed,
                    title: "개인정보 수집 및 이용 동의서 상세",
                    showDetail: true,
                    detailURLString: "https://www.naver.com/"
                )
                agreementRow(
                    isChecked: $viewModel.isPrivacyPolicyAgreed,
                    title: "개인정보 처리방침 상세",
                    showDetail: true,
                    detailURLString: "https://www.naver.com/"
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)

            Spacer()

            Button(action: {
                // MARK: - 약관 동의 유무 UserDefaults에 저장
                UserDefaults.standard.set(true, forKey: "didAgreeToTerms")
                completion()
            }) {
                Text("확인")
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.black)
                    .cornerRadius(8)
            }
            .padding(20)
            .disabled(!viewModel.canProceed)
            .opacity(viewModel.canProceed ? 1 : 0.5)
        }
        .background(Color.white)
        .cornerRadius(24)
        .fullScreenCover(isPresented: $showingDetail) {
            NavigationStack {
                TermsDetailView(
                    title: detailTitle,
                    urlString: detailURLString
                )
                .toolbar {
                    ToolbarItem {
                        HStack (alignment: .center) {
                            Text(detailTitle)
                                .font(.headline)
                            
                            Spacer()
                            
                            Button("X") {
                                showingDetail = false
                            }
                            .foregroundStyle(Color.black)
                        }
                        
                    }
                }
            }
        }
    }
    
    // MARK: - 이용 약관 Row
    private func agreementRow(
        isChecked: Binding<Bool>,
        title: String,
        isBold: Bool = false,
        showDetail: Bool = false,
        detailURLString: String? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        HStack {
            Button(action: {
                isChecked.wrappedValue.toggle()
                action?()
            }) {
                Image(
                    systemName: isChecked.wrappedValue ? "checkmark.square.fill" : "square"
                )
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(.black)
            }

            Text(title)
                .font(isBold ? .body.bold() : .body)

            Spacer()

            if showDetail, let detailURLString = detailURLString {
                Button {
                    detailTitle = title
                    self.detailURLString = detailURLString
                    showingDetail = true
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
}

struct TermsDetailView: View {
    let title: String
    let urlString: String

    var body: some View {
        VStack {
            if let url = URL(string: urlString) {
                WebView(url: url)
            } else {
                Text("유효하지 않은 URL입니다.")
                    .foregroundColor(.red)
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}

#Preview {
    TermsView(viewModel: TermsViewModel()) {
        
    }
}
