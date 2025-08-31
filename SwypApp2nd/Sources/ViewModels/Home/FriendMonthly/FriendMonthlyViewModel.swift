//
//  FriendMonthlyViewModel.swift
//  SwypApp2nd
//
//  Created by 정종원 on 8/31/25.
//

import Foundation

class FriendMonthlyViewModel: ObservableObject {
    // 홈뷰에서 가져온 이번달 친구 목록
    @Published var peoples: [FriendMonthlyResponse] = []
    
    // 가공된 데이터들
    @Published var pendingFriends: [FriendMonthlyResponse] = []
    @Published var completedFriends: [FriendMonthlyResponse] = []
    
    init() {}
    
    // 데이터 설정 및 가공
    func setPeoples(_ peoples: [FriendMonthlyResponse]) {
        self.peoples = peoples
        processData()
    }
    
    // 데이터 가공 로직
    private func processData() {
        //(테스트용)
        pendingFriends = peoples
        completedFriends = peoples
        
        print("🟡 [FriendMonthlyViewModel] processData 완료")
        print("🟡 [FriendMonthlyViewModel] peoples count: \(peoples.count)")
        print("🟡 [FriendMonthlyViewModel] pendingFriends count: \(pendingFriends.count)")
        print("🟡 [FriendMonthlyViewModel] completedFriends count: \(completedFriends.count)")
    }
    
//    @Published var checkInRecords: [CheckInRecord] = []
    
//    var canCheckInToday: Bool {
//        guard let kstTimeZone = TimeZone(identifier: "Asia/Seoul") else {
//            fatalError("Could not load KST time zone")
//        }
//        var calendar = Calendar.current
//        calendar.timeZone = kstTimeZone
//
//        let today = calendar.startOfDay(for: .now)
//
//        return !checkInRecords.contains { record in
//            let recordDate = calendar.startOfDay(for: record.createdAt)
//            return recordDate == today && record.isChecked
//        }
//    }
}

