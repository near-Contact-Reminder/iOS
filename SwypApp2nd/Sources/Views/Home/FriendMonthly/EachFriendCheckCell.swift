//
//  EachFriendCheckCell.swift
//  SwypApp2nd
//
//  Created by 정종원 on 8/18/25.
//

import Foundation
import SwiftUI

public struct EachFriendCheckCell: View {
    
    @State private var showToast = false
    
    public var body: some View {
        ZStack {
            
            // 챙김 기록시 나오는 뷰
            if showToast {
                CareToastView()
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(1)
            }
            
            VStack(spacing: 12) {
                // 상단: 아이콘, 이름, D-DAY
                HStack(spacing: 12) {
                    // 생일 케이크 아이콘
                    Image("icon_visual_cake")
                        .resizable()
                        .frame(width: 32, height: 32)
                    
                    // 이름과 메시지
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("홍길동")
                                .modifier(Font.Pretendard.b1BoldStyle())
                                .foregroundColor(.black)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            // D-DAY 표시
                            Text("D-DAY")
                                .modifier(Font.Pretendard.captionMediumStyle())
                                .foregroundColor(Color.gray02)
                            
                        }
                        
                        Text("생일 축하 전해요")
                            .modifier(Font.Pretendard.b2MediumStyle())
                            .foregroundColor(.gray02)
                    }
                }
                
                //챙김 기록하기 버튼
                Button {
                    // TODO: - 챙김 기록 apu call, 애니매이션 작업
                    // TODO: - GA연결
                    
                    // 아래는 친구 상세 화면에서 챙김 기록시 로직
//                    viewModel.checkFriend() {
//                        presentToastTemporarily()
//                        viewModel.fetchFriendRecords(friendId: viewModel.people.id)
//                    }
//                    AnalyticsManager.shared.dailyCheckButtonLogAnalytics()
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
        }
        .padding(.horizontal, 20)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 8)
    }
}

struct EachFriendCheckCell_Previews: PreviewProvider {
    static var previews: some View {
        EachFriendCheckCell()
    }
}
