//
//  CareToastView.swift
//  SwypApp2nd
//
//  Created by 정종원 on 11/26/25.
//

import Foundation
import SwiftUI

public struct CareToastView: View {
    public var body: some View {
        VStack(spacing: 12) {
            Image("img_100_character_success")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)

            Text("더 가까워졌어요!")
                .font(Font.Pretendard.b1Medium())
                .foregroundColor(.black)
        }
        .padding(32)
        .frame(width: 255, height: 186)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        )
        .transition(.scale.combined(with: .opacity))
    }
}
