//
//  FriendMonthlyViewModel.swift
//  SwypApp2nd
//
//  Created by 정종원 on 8/31/25.
//

import Foundation
import SwiftUI

class FriendMonthlyViewModel: ObservableObject {
    // 홈뷰에서 가져온 이번달 친구 목록
    @Published var peoples: [FriendMonthlyResponse] = []
    
    // 가공된 데이터들
    @Published var pendingFriends: [FriendMonthlyResponse] = []
    @Published var completedFriends: [FriendMonthlyResponse] = []
    
    // 챙김 기록 애니메이션
    @Published var showToast = false
    @Published var toastMessage = ""
    
    init() {}
    
    // 데이터 설정 및 가공
    func setPeoples(_ peoples: [FriendMonthlyResponse]) {
        self.peoples = peoples
        processData()
    }
    
    // 데이터 가공 로직
    private func processData() {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        // 이번달 시작일과 끝일 계산
        let startOfMonth = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        var pending: [FriendMonthlyResponse] = []
        var completed: [FriendMonthlyResponse] = []
        
        for person in peoples {
            // lastContactAt이 있고, 이번달 범위 내에 있는지 확인
            if let lastContactAtString = person.lastContactAt,
               let lastContactDate = lastContactAtString.toDateWithDot() {
                
                // 마지막 연락일이 이번달 범위 내에 있으면 완료된 친구
                if lastContactDate >= startOfMonth && lastContactDate <= endOfMonth {
                    completed.append(person)
                } else {
                    // 이번달에 연락하지 않았으면 대기 중인 친구
                    pending.append(person)
                }
            } else {
                // lastContactAt 정보가 없으면 대기 중인 친구로 분류
                pending.append(person)
            }
        }
        
        // nextContactAt 기준으로 정렬 (가까운 날짜 순)
        pendingFriends = pending.sorted { lhs, rhs in
            lhs.nextContactAt < rhs.nextContactAt
        }
        
        // 최근 연락한 순으로 정렬
        completedFriends = completed.sorted { lhs, rhs in
            guard let lhsDate = lhs.lastContactAt?.toDateWithDot(),
                  let rhsDate = rhs.lastContactAt?.toDateWithDot() else {
                return false
            }
            return lhsDate > rhsDate // 최근 날짜가 먼저 오도록
        }
        
        print("🟡 [FriendMonthlyViewModel] processData 완료")
        print("🟡 [FriendMonthlyViewModel] peoples count: \(peoples.count)")
        print("🟡 [FriendMonthlyViewModel] pendingFriends count: \(pendingFriends.count)")
        print("🟡 [FriendMonthlyViewModel] completedFriends count: \(completedFriends.count)")
        
        // 디버깅용 로그
        for friend in pendingFriends {
            print("🟡 [Pending] \(friend.name) - lastContactAt: \(friend.lastContactAt ?? "nil")")
        }
        
        for friend in completedFriends {
            print("🟢 [Completed] \(friend.name) - lastContactAt: \(friend.lastContactAt ?? "nil")")
        }
    }
    
    @Published var checkInRecords: [CheckInRecord] = []
    
    var canCheckInToday: Bool {
        guard let kstTimeZone = TimeZone(identifier: "Asia/Seoul") else {
            fatalError("Could not load KST time zone")
        }
        var calendar = Calendar.current
        calendar.timeZone = kstTimeZone

        let today = calendar.startOfDay(for: .now)

        return !checkInRecords.contains { record in
            let recordDate = calendar.startOfDay(for: record.createdAt)
            return recordDate == today && record.isChecked
        }
    }
    
    // 챙김 기록하기 메서드
    func checkFriend(friendId: String, completion: @escaping (Bool, String?) -> Void) {
        guard let token = UserSession.shared.user?.serverAccessToken,
              let uuid = UUID(uuidString: friendId) else {
            completion(false, "토큰 또는 친구 ID가 유효하지 않습니다.")
            return
        }
        
        BackEndAuthService.shared.postFriendCheck(
            friendId: uuid,
            accessToken: token
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let message):
                    print("🟢 [FriendMonthlyViewModel] 챙김 성공: \(message)")
                    // 토스트 표시
                    self.presentToastTemporarily()
                    // 챙김 성공 후 데이터 새로고침
                    self.refreshData()
                    completion(true, message)
                case .failure(let error):
                    print("🔴 [FriendMonthlyViewModel] 챙김 실패: \(error)")
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
    
    // 데이터 새로고침
    private func refreshData() {
        
        // homeViewModel 새로고침 요청
        NotificationCenter.default.post(
            name: NSNotification.Name("RefreshMonthlyFriends"),
            object: nil
        )
        print("🟡 [FriendMonthlyViewModel] 데이터 새로고침 필요")
    }
    
    // 챙김기록 애니메이션
    private func presentToastTemporarily() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.showToast = false
            }
        }
    }
}

