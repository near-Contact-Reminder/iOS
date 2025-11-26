//
//  EachFriendCheckCell.swift
//  SwypApp2nd
//
//  Created by 정종원 on 8/18/25.
//

import Foundation
import SwiftUI

public struct EachFriendCheckCell: View {
    
    let people: FriendMonthlyResponse
    @ObservedObject var viewModel: FriendMonthlyViewModel
    
    public var body: some View {
        VStack(spacing: 12) {
            // 상단: 아이콘, 이름, D-DAY
            HStack(spacing: 12) {
                // 생일 케이크 아이콘
                Image(getIconName(for: people.type))
                    .resizable()
                    .frame(width: 32, height: 32)
                
                // 이름과 메시지
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(people.name)
                            .modifier(Font.Pretendard.b1BoldStyle())
                            .foregroundColor(.black)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // D-DAY 표시
                        Text(dDayString)
                            .modifier(Font.Pretendard.captionMediumStyle())
                            .foregroundColor(Color.gray02)
                        
                    }
                    
                    Text(getIconDescription(for: people.type))
                        .modifier(Font.Pretendard.b2MediumStyle())
                        .foregroundColor(.gray02)
                }
            }
            
            //챙김 기록하기 버튼
            Button {
                // TODO: - GA연결
                
                // 아래는 친구 상세 화면에서 챙김 기록시 로직
                viewModel.checkFriend(friendId: people.friendId) { success, message in
                    if success {
                        AnalyticsManager.shared
                            .dailyCheckButtonLogAnalytics()
                    } else {
                        print("챙김 기록 실패: \(message ?? "알 수 없는 오류")")
                    }
                }
                AnalyticsManager.shared.dailyCheckButtonLogAnalytics()
                print("챙김 기록하기")
            } label: {
                HStack {
                    Spacer()
                    Text("챙김 기록하기")
                        .modifier(Font.Pretendard.b1BoldStyle())
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.vertical, 12)
                .background(Color.blue01)
                .cornerRadius(12)
            }
            .frame(height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: -1)
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
    
    private func getIconDescription(for type: String) -> String {
        switch type {
        case "MESSAGE": return "가볍게 안부 전해요"
        case "BIRTHDAY": return "생일 축하 전해요"
        case "ANNIVERSARY": return "소중한 날 마음을 전해요"
        default: return "가볍게 안부 전해요"
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
