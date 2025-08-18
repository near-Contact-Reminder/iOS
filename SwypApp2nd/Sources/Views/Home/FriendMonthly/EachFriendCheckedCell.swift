//
//  EachFriendCheckedCell.swift
//  SwypApp2nd
//
//  Created by 정종원 on 8/18/25.
//

import Foundation
import SwiftUI

public struct EachFriendCheckedCell: View {
    public var body: some View {
        HStack(spacing: 12) {
            // 생일 케이크 아이콘
            Image("icon_visual_cake")
                .resizable()
                .frame(width: 32, height: 32)
            
            // 이름
            Text("홍길동")
                .modifier(Font.Pretendard.b1BoldStyle())
                .foregroundColor(.black)
                .lineLimit(1)
            
            Spacer()
            
            // D-DAY 표시
            Text("D-DAY")
                .modifier(Font.Pretendard.b2MediumStyle())
                .foregroundColor(Color.gray02)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(Color.bg02)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 8)
    }
}
