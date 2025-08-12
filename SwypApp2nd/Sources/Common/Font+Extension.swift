import Foundation
import SwiftUI

extension Font {
    struct Pretendard {
        static func h1Bold(size: CGFloat = 24) -> Font {
            Font.custom("Pretendard-Bold", size: size)
        }
        static func h1Medium(size: CGFloat = 24) -> Font {
            Font.custom("Pretendard-Medium", size: size)
        }
        static func h1Regular(size: CGFloat = 24) -> Font {
            Font.custom("Pretendard-Regular", size: size)
        }
        static func h2Bold(size: CGFloat = 18) -> Font {
            Font.custom("Pretendard-Bold", size: size)
        }
        static func b1Bold(size: CGFloat = 16) -> Font {
            Font.custom("Pretendard-Bold", size: size)
        }
        static func b1Medium(size: CGFloat = 16) -> Font {
            Font.custom("Pretendard-Medium", size: size)
        }
        static func b2Bold(size: CGFloat = 14) -> Font {
            Font.custom("Pretendard-Bold", size: size)
        }
        static func b2Medium(size: CGFloat = 14) -> Font {
            Font.custom("Pretendard-Medium", size: size)
        }
        static func captionBold(size: CGFloat = 12) -> Font {
            Font.custom("Pretendard-Bold", size: size)
        }
        static func captionMedium(size: CGFloat = 12) -> Font {
            Font.custom("Pretendard-Medium", size: size)
        }

        // ViewModifier 반환
        static func h1BoldStyle() -> PretendardTextStyle { 
            .init(font: h1Bold(), fontSize: 24, designLineHeight: 34, letterSpacing: -0.25) 
        }
        static func h1MediumStyle() -> PretendardTextStyle { 
            .init(font: h1Medium(), fontSize: 24, designLineHeight: 34, letterSpacing: -0.25) 
        }
        static func h1RegularStyle() -> PretendardTextStyle { 
            .init(font: h1Regular(), fontSize: 24, designLineHeight: 34, letterSpacing: -0.25) 
        }
        static func h2BoldStyle() -> PretendardTextStyle { 
            .init(font: h2Bold(), fontSize: 18, designLineHeight: 24, letterSpacing: -0.25) 
        }
        static func b1BoldStyle() -> PretendardTextStyle { 
            .init(font: b1Bold(), fontSize: 16, designLineHeight: 22, letterSpacing: -0.25) 
        }
        static func b1MediumStyle() -> PretendardTextStyle { 
            .init(font: b1Medium(), fontSize: 16, designLineHeight: 22, letterSpacing: -0.25) 
        }
        static func b2BoldStyle() -> PretendardTextStyle { 
            .init(font: b2Bold(), fontSize: 14, designLineHeight: 20, letterSpacing: -0.25) 
        }
        static func b2MediumStyle() -> PretendardTextStyle { 
            .init(font: b2Medium(), fontSize: 14, designLineHeight: 20, letterSpacing: -0.25) 
        }
        static func captionBoldStyle() -> PretendardTextStyle { 
            .init(font: captionBold(), fontSize: 12, designLineHeight: 18, letterSpacing: -0.25) 
        }
        static func captionMediumStyle() -> PretendardTextStyle { 
            .init(font: captionMedium(), fontSize: 12, designLineHeight: 18, letterSpacing: -0.25) 
        }
    }
}

// PretendardTextStyle ViewModifier
struct PretendardTextStyle: ViewModifier {
    let font: Font
    let fontSize: CGFloat
    let designLineHeight: CGFloat
    let letterSpacing: CGFloat

    func body(content: Content) -> some View {
        content
            .font(font)
            .lineSpacing(calculateLineSpacing())
            .tracking(letterSpacing)
    }
    
    /// lineSpacing 계산
    private func calculateLineSpacing() -> CGFloat {
        if let uiFont = getUIFont() {
            let actualLineHeight = uiFont.lineHeight
            let additionalSpacing = designLineHeight - actualLineHeight
            return max(0, additionalSpacing)
        }
        
        // 폰트별 경험적 계수 사용
        let coefficient = getLineHeightCoefficient()
        let estimatedDefaultLineHeight = fontSize * coefficient
        let additionalSpacing = designLineHeight - estimatedDefaultLineHeight
        
        return max(0, additionalSpacing)
    }
    
    // UIFont 인스턴스 가져오기
    private func getUIFont() -> UIFont? {
        // Pretendard 폰트의 실제 이름 매핑
        let fontNames = [
            "Pretendard-Bold": "PretendardBold",
            "Pretendard-Medium": "PretendardMedium", 
            "Pretendard-Regular": "PretendardRegular"
        ]
        
        // font에서 폰트 이름 추출/ 매핑
        for (searchName, realName) in fontNames {
            if String(describing: font).contains(searchName) {
                return UIFont(name: realName, size: fontSize)
            }
        }
        
        return UIFont.systemFont(ofSize: fontSize)
    }
    
    // 폰트 크기별 line height 계수
    private func getLineHeightCoefficient() -> CGFloat {
        switch fontSize {
        case 24: return 1.25 // H1
        case 18: return 1.22 // H2
        case 16: return 1.19 // B1
        case 14: return 1.21 // B2
        case 12: return 1.17 // Caption
        default: return 1.2 // 기본값
        }
    }
}

// MARK: - Example
/*
Text("Example")
   .modifier(Font.Pretendard.h1BoldStyle())
*/
