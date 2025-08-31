import Foundation
import SwiftUI
import UIKit

public struct FriendMonthlyView: View {
    @ObservedObject var viewModel: FriendMonthlyViewModel
    @Binding var path: [AppRoute]
    
    let peoples: [FriendMonthlyResponse]
    
    public var body: some View {
        VStack(spacing: 0) {
            
            // 콘텐츠 영역
            ScrollView {
                LazyVStack(spacing: 24) {
                    // 챙겨야 하는 섹션
                    if !viewModel.pendingFriends.isEmpty {
                        VStack(spacing: 0) {
                            
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.pendingFriends, id: \.friendId) { friend in
                                    EachFriendCheckCell(people: friend)
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        }
                    } // 챙겨야 하는 섹션
                    
                    // 챙김 완료한 섹션
                    if !viewModel.completedFriends.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            
                            Text("챙김 완료")
                                .modifier(Font.Pretendard.b1MediumStyle())
                                .foregroundColor(.black)
                            
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.completedFriends, id: \.friendId) { friend in
                                    EachFriendCheckedCell(people: friend)
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        }
                    } // 챙김 완료한 섹션
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            } // 콘텐츠 영역
        }
        .onAppear {
            // 데이터를 ViewModel에 전달
            print("🟡 [FriendMonthlyView] onAppear - peoples count: \(peoples.count)")
            for (index, people) in peoples.enumerated() {
                print("🟡 [FriendMonthlyView] people[\(index)]: \(people.name) - \(people.type)")
            }
            viewModel.setPeoples(peoples)
        }
        .background(Color.white)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(Color.white, for: .navigationBar) // 배경 흰색
        .toolbar {
            ToolbarItem(placement: .topBarLeading)  {
                Button(action: {
                    path.removeLast()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("이번달 챙길 사람")
                    }
                    .foregroundColor(.black)
                    .font(Font.Pretendard.b1Bold())
                }
                .padding(.leading, 12)
            }
        }
    }
    
}
