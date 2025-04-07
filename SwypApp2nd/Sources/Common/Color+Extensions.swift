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
    
    // GrayScale
    static let gray01 = Color("Gray01_Text")
    static let gray02 = Color("Gray02_Disable")
    static let gray03 = Color("Gray03_Line")
    static let gray04 = Color("Gray04_DisableBg")

    // Primary
    static let blue01 = Color("Blue01")
    static let blue02 = Color("Blue02")

    // Semantic
    static let negative = Color("Negative")

    // Background
    static let bg01 = Color("Bg01")
    static let bg02 = Color("Bg02")

    // Dimmed
    static let dimmed60 = Color("Dimmed_60")
    
    // 카카오톡 버튼
    static let kakaoBackgroundColor = Color(hex: "#FAE64D")

    // Inbox 읽음 백그라운드 
    static let readBlue = Color(hex: "#F4F9FD")

}

// MARK: - Example
/*
Text("Near")
    .foregroundStyle(Color.blue01)
*/
