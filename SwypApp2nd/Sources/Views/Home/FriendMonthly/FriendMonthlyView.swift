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

struct FriendMonthlyView_Previews: PreviewProvider {
    static var previews: some View {
        FriendMonthlyPreviewWrapper(peoples: samplePeoples)
            .previewDisplayName("Friend Monthly")
    }

    private static let samplePeoples: [FriendMonthlyResponse] = [
        FriendMonthlyResponse(friendId: "1", name: "김다정", type: "MESSAGE", nextContactAt: "2024-09-20"),
        FriendMonthlyResponse(friendId: "2", name: "이민수", type: "BIRTHDAY", nextContactAt: "2024-09-25"),
        FriendMonthlyResponse(friendId: "3", name: "박서준", type: "ANNIVERSARY", nextContactAt: "2024-10-02")
    ]

    private struct FriendMonthlyPreviewWrapper: View {
        @State private var path: [AppRoute] = []
        @StateObject private var viewModel = FriendMonthlyViewModel()

        let peoples: [FriendMonthlyResponse]

        var body: some View {
            FriendMonthlyView(viewModel: viewModel, path: $path, peoples: peoples)
        }
    }
}
