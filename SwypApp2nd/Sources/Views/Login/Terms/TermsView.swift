import SwiftUI
import Combine
import WebKit

struct AgreementDetail: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let urlString: String
}

public struct TermsView: View {
    @ObservedObject var viewModel = TermsViewModel()
    
    // 약관 상세를 보여주기 위한 상태 관리
    @State private var selectedAgreement: AgreementDetail?
    @State private var alertMessage: String?
    
    let completion: () -> Void

    public var body: some View {
        VStack(alignment: .leading) {

            Text("서비스 약관 동의")
                .modifier(Font.Pretendard.h2BoldStyle())
                .padding(.leading, 24)
                .padding(.top, 44)

            Group {
                if viewModel.isLoading && viewModel.terms.isEmpty {
                    VStack {
                        ProgressView("약관을 불러오는 중입니다...")
                        Text("잠시만 기다려 주세요.")
                            .modifier(Font.Pretendard.b1MediumStyle())
                            .foregroundColor(Color.gray04)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                } else if viewModel.terms.isEmpty {
                    VStack(spacing: 12) {
                        Text("약관 정보를 불러오지 못했어요.")
                            .modifier(Font.Pretendard.b1BoldStyle())
                        Text("네트워크 상태를 확인한 뒤 다시 시도해 주세요.")
                            .modifier(Font.Pretendard.b1MediumStyle())
                            .foregroundColor(Color.gray04)
                        Button(action: {
                            viewModel.refresh()
                        }) {
                            Text("다시 시도")
                                .modifier(Font.Pretendard.b2BoldStyle())
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue01)
                                .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                } else {
                    LazyVStack(spacing: 12) {
                        AgreementRow(
                            isChecked: Binding(
                                get: { viewModel.isAllAgreed },
                                set: { newValue in viewModel.updateAllAgreements(to: newValue) }
                            ),
                            title: "약관 전체 동의",
                            isBold: true
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray03, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        VStack(spacing: 0) {
                            ForEach(Array(viewModel.terms.enumerated()), id: \.element.id) { index, term in
                                AgreementRow(
                                    isChecked: viewModel.binding(for: term),
                                    title: formattedTitle(for: term),
                                    isBold: false,
                                    showDetail: viewModel.detailURL(for: term) != nil,
                                    detailURLString: viewModel.detailURL(for: term),
                                    onDetailTappedClosure: { title, url in
                                        self.selectedAgreement = AgreementDetail(title: title, urlString: url)
                                    }
                                )
                                
                                if index < viewModel.terms.count - 1 {
                                    Divider()
                                        .background(Color.gray03)
                                        .padding(.horizontal, 14)
                                }
                            }
                        }
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray03, lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            if let errorMessage = viewModel.errorMessage, !viewModel.isLoading {
                Text(errorMessage)
                    .modifier(Font.Pretendard.captionMediumStyle())
                    .foregroundColor(.red)
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
            }

            Spacer()

            Button(action: {
                viewModel.submitAgreements { result in
                    switch result {
                    case .success:
                        AnalyticsManager.shared.agreementLogAnalytics()
                        completion()
                    case .failure(let error):
                        alertMessage = error.errorDescription ?? "약관 동의에 실패했습니다."
                    }
                }
            }) {
                ZStack {
                    Text("가입")
                        .foregroundColor(.white)
                        .modifier(Font.Pretendard.b1BoldStyle())
                        .opacity(viewModel.isSubmitting ? 0 : 1)
                    
                    if viewModel.isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(viewModel.canProceed ? Color.blue01 : Color.gray02)
                .cornerRadius(8)
            }
            .padding(20)
            .disabled(!viewModel.canProceed || viewModel.isSubmitting)
        }
        .background(Color.white)
        .cornerRadius(24)
        .fullScreenCover(item: $selectedAgreement) { agreement in
            NavigationStack {
                TermsDetailView(
                    title: agreement.title,
                    urlString: agreement.urlString
                )
                .presentationDetents([.large])
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Text(agreement.title)
                            .modifier(Font.Pretendard.b1MediumStyle())
                            .foregroundStyle(Color.black)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            selectedAgreement = nil
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundStyle(.black)
                        }
                    }
                }
            }
        }
        .onAppear {
            AnalyticsManager.shared.trackTermsViewLogAnalytics()
            viewModel.loadTerms()
        }
        .alert("알림", isPresented: Binding(
            get: { alertMessage != nil },
            set: { newValue in
                if !newValue {
                    alertMessage = nil
                }
            }
        )) {
            Button("확인", role: .cancel) {
                alertMessage = nil
            }
        } message: {
            Text(alertMessage ?? "")
        }
    }
    
    private func formattedTitle(for term: TermItem) -> String {
        let prefix = term.isRequired ? "[필수] " : "[선택] "
        return prefix + term.title
    }
}
/// 이용 약관 Row
public struct AgreementRow: View {
    var isChecked: Binding<Bool>
    var title: String
    var isBold: Bool = false
    var showDetail: Bool = false
    var detailURLString: String? = nil
    
    var checkBoxTappedClosure: (() -> Void)? = nil
    var onDetailTappedClosure: ((String, String) -> Void)?
    
    public init(
            isChecked: Binding<Bool>,
            title: String,
            isBold: Bool = false,
            showDetail: Bool = false,
            detailURLString: String? = nil,
            checkBoxTappedClosure: (() -> Void)? = nil,
            onDetailTappedClosure: ((String, String) -> Void)? = nil
        ) {
            self.isChecked = isChecked
            self.title = title
            self.isBold = isBold
            self.showDetail = showDetail
            self.detailURLString = detailURLString
            self.checkBoxTappedClosure = checkBoxTappedClosure
            self.onDetailTappedClosure = onDetailTappedClosure
        }
    
    public var body: some View {
        HStack {
            Button(action: {
                isChecked.wrappedValue.toggle()
                checkBoxTappedClosure?()
            }) {
                if isBold {
                    // 전체 동의용 체크박스 스타일
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(
                                isChecked.wrappedValue ? Color.blue01 : Color.gray03,
                                lineWidth: 2
                            )
                            .frame(width: 24, height: 24)
                            .background(
                                isChecked.wrappedValue ? Color.blue01 : Color.gray03
                            )
                            .cornerRadius(6)

                        
                        Image("icon_check_white")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                        
                    }
                } else {
                    // 하단 3개의 약관 체크 아이콘
                    (isChecked.wrappedValue ?
                          Image.Icon.checkBlue
                          : Image.Icon.checkGray)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                }
            }
            
            Text(title)
                .modifier(isBold ? Font.Pretendard.b1BoldStyle() : Font.Pretendard.b1MediumStyle())
                .foregroundStyle(Color.black)
            
            Spacer()
            
            if showDetail, let detailURLString = detailURLString {
                Button {
                    onDetailTappedClosure?(title, detailURLString)
                } label: {
                    Image.Icon.next
                        .foregroundColor(Color(hex: "888888"))
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
    }
}

struct TermsDetailView: View {
    let title: String?
    let urlString: String?
    
    @State private var isLoading = true

    var body: some View {
        VStack {
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView("로딩 중...")
                    Spacer()
                }
            }
            
            if let urlString = urlString, let url = URL(string: urlString) {
                WebView(url: url)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .opacity(isLoading ? 0 : 1)
            } else if !isLoading {
                Text("유효하지 않은 URL입니다.")
                    .foregroundColor(.red)
                    .padding()
                    .opacity(isLoading ? 0 : 1)
                let _ = print("🔴 [TermsDetailView] 유효하지 않은 URL 입니다. ")
            }
            
        }
        .onAppear {
            if let urlString = urlString, let url = URL(string: urlString) {
                print("🟢 [TermsDetailView] URL 파싱 성공: \(url)")
                isLoading = false
            } else {
                print(
                    "🔴 [TermsDetailView] URL 파싱 실패: \(String(describing: urlString))"
                )
                isLoading = false
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
        
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
        
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
        
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
        
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(
            _ webView: WKWebView,
            didStartProvisionalNavigation navigation: WKNavigation!
        ) {
            print("🟡 웹뷰 로딩 시작")
        }
            
        func webView(
            _ webView: WKWebView,
            didFinish navigation: WKNavigation!
        ) {
            print("🟢 웹뷰 로딩 완료")
        }
            
        func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation!,
            withError error: Error
        ) {
            print("🔴 웹뷰 로딩 실패: \(error.localizedDescription)")
        }
    }
}

#Preview {
    TermsView(viewModel: TermsViewModel()) {
        
    }
}
