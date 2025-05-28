import SwiftUI

struct OnBoardingView: View {
    
    @State private var currentPage = 0
    var onBoardingDoneAction: () -> Void
    private let images = [
        Image.OnBoarding.Onboarding1_Home,
        Image.OnBoarding.Onboarding2_addProfile,
        Image.OnBoarding.Onboarding3_Frequency,
        Image.OnBoarding.Onboarding4_ProfileDetail
    ]
    
    var body: some View {
        ZStack {
            Image("img_onboarding_bg")
                .resizable()
                .ignoresSafeArea()
            
            VStack(alignment: .center, spacing: 16) {
                
                Spacer()
                    .frame(height: 32)
                
                // 상단 텍스트
                VStack(spacing: 8) {
                    Text(title(for: currentPage))
                        .font(Font.Pretendard.h1Bold())
                        .foregroundColor(.black)
                                
                    Text(subtitle(for: currentPage))
                        .font(Font.Pretendard.h1Bold())
                        .foregroundColor(.blue01)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .top)
                
                // 스크린샷
                TabView(selection: $currentPage) {
                    ForEach(0 ..< images.count, id: \.self) { index in
                        images[index]
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)
                
                // 페이지 인디케이터
                HStack(spacing: 8) {
                    ForEach(0..<images.count, id: \.self) { index in
                        Circle()
                            .fill(
                                index == currentPage ? Color.blue01 : Color.gray04
                            )
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.vertical, 8)

                Button(action: {
                    if currentPage < images.count - 1 {
                        currentPage += 1
                    } else {
                        onBoardingDoneAction()
                    }
                }) {
                    Text("다음")
                        .font(Font.Pretendard.b1Medium())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue01)
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                }
            }
        }
    }
    
    // MARK: - Methods
    private func title(for index: Int) -> String {
        switch index {
        case 0: return "소중한 사람들과"
        case 1: return "연락처로 간편하게"
        case 2: return "챙기고 싶은 날에"
        case 3: return "오늘도 잘 챙겼는지"
        default: return ""
        }
    }

    private func subtitle(for index: Int) -> String {
        switch index {
        case 0: return "더 가까워질 수 있도록"
        case 1: return "챙길 사람 등록"
        case 2: return "알림 받기"
        case 3: return "기록 남기기"
        default: return ""
        }
    }
}

#Preview {
    OnBoardingView(onBoardingDoneAction: { print("Done")})
}
