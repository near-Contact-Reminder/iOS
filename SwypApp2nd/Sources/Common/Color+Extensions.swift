import Foundation
import SwiftUI

extension Color {
    // Hex값 색상 지원
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hex)
        if hex.hasPrefix("#") {
            _ = scanner.scanString("#")
        }

        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255

        self.init(red: r, green: g, blue: b)
    }
    
    // TODO: - 사용할 색상 미리 저장
    static let mainYellow = Color(hex: "#FFFFF")
    
    static let kakaoBackgroundColor = Color(hex: "#FAE64D")
}
