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
        static func h1BoldStyle() -> PretendardTextStyle { .init(font: h1Bold(), lineHeight: 34, letterSpacing: -0.25) }
        static func h1MediumStyle() -> PretendardTextStyle { .init(font: h1Medium(), lineHeight: 34, letterSpacing: -0.25) }
        static func h1RegularStyle() -> PretendardTextStyle { .init(font: h1Regular(), lineHeight: 34, letterSpacing: -0.25) }
        static func h2BoldStyle() -> PretendardTextStyle { .init(font: h2Bold(), lineHeight: 24, letterSpacing: -0.25) }
        static func b1BoldStyle() -> PretendardTextStyle { .init(font: b1Bold(), lineHeight: 22, letterSpacing: -0.25) }
        static func b1MediumStyle() -> PretendardTextStyle { .init(font: b1Medium(), lineHeight: 22, letterSpacing: -0.25) }
        static func b2BoldStyle() -> PretendardTextStyle { .init(font: b2Bold(), lineHeight: 20, letterSpacing: -0.25) }
        static func b2MediumStyle() -> PretendardTextStyle { .init(font: b2Medium(), lineHeight: 20, letterSpacing: -0.25) }
        static func captionBoldStyle() -> PretendardTextStyle { .init(font: captionBold(), lineHeight: 18, letterSpacing: -0.25) }
        static func captionMediumStyle() -> PretendardTextStyle { .init(font: captionMedium(), lineHeight: 18, letterSpacing: -0.25) }
    }
}

// PretendardTextStyle ViewModifier
struct PretendardTextStyle: ViewModifier {
    let font: Font
    let lineHeight: CGFloat
    let letterSpacing: CGFloat

    func body(content: Content) -> some View {
        content
            .font(font)
            .lineSpacing(lineHeight - fontSize(from: font))
            .tracking(letterSpacing)
    }

    // Pretendard 폰트 크기 추출 (Font.custom 사용 시)
    private func fontSize(from font: Font) -> CGFloat {
        // Pretendard-XX, size: YY
        let mirror = Mirror(reflecting: font)
        for child in mirror.children {
            if let provider = child.value as? CTFontProvider,
               let size = provider.fontSize {
                return size
            }
        }
        // 기본값
        return 16
    }
}

// CTFontProvider 프로토콜
private protocol CTFontProvider {
    var fontSize: CGFloat? { get }
}
extension CTFontProvider {
    var fontSize: CGFloat? { nil }
}

// MARK: - Example
/*
Text("Example")
   .modifier(Font.Pretendard.h1BoldStyle())
*/
