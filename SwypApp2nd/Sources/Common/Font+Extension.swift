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
    }
}

// MARK: - Example
/*
Text("Example")
   .font(Font.Pretendard.h1Bold())
   .tracking(-0.25)
   .lineSpacing(10)
*/
