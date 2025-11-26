//
//  EachFriendCheckedCell.swift
//  SwypApp2nd
//
//  Created by 정종원 on 8/18/25.
//

import Foundation
import SwiftUI

public struct EachFriendCheckedCell: View {
    
    let people: FriendMonthlyResponse
    
    public var body: some View {
        HStack(spacing: 12) {
            // 생일 케이크 아이콘
            Image(getIconName(for: people.type))
                .resizable()
                .frame(width: 32, height: 32)
            
            // 이름
            Text(people.name)
                .modifier(Font.Pretendard.b1BoldStyle())
                .foregroundColor(.black)
                .lineLimit(1)
            
            Spacer()
            
            // D-DAY 표시
            Text(dDayString)
                .modifier(Font.Pretendard.b2MediumStyle())
                .foregroundColor(Color.gray02)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(Color.bg02)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: -1)
    }
    
    // MARK: - Helpers
    
    private func getIconName(for type: String) -> String {
        switch type {
        case "MESSAGE": return "icon_visual_mail"
        case "BIRTHDAY": return "icon_visual_cake"
        case "ANNIVERSARY": return "icon_visual_24_heart"
        default: return "icon_visual_mail"
        }
    }
        
    private func getDisplayMessage(for type: String) -> String {
        switch type {
        case "MESSAGE": return "주기적으로 연락 드려요"
        case "BIRTHDAY": return "생일 축하 전해요"
        case "ANNIVERSARY": return "기념일 축하해요"
        default: return "주기적으로 연락 드려요"
        }
    }
    
    var dDayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy-MM-dd"
        guard let target = formatter.date(from: people.nextContactAt) else {
            return ""
        }

        let today = Calendar.current.startOfDay(for: Date().startOfDayInKorea())
        let targetDay = Calendar.current.startOfDay(for: target.startOfDayInKorea())
        let diff = Calendar.current.dateComponents(
            [.day],
            from: today,
            to: targetDay
        ).day ?? 0

        if diff == 0 {
            return "D-DAY"
        } else if diff > 0 {
            return "D-\(diff)"
        } else {
            return "D+\(-diff)"
        }
    }
}
