import Foundation
import Combine
import UIKit

enum CheckInFrequency: String, CaseIterable, Identifiable {
    case none = "주기 선택"
    case daily = "매일"
    case weekly = "매주"
    case biweekly = "2주"
    case monthly = "매달"
    case semiAnnually = "6개월"
    
    var id: String { rawValue }
}

class ContactFrequencySettingsViewModel: ObservableObject {
    @Published var people: [Friend] = []
    @Published var isUnified: Bool = false
    @Published var unifiedFrequency: CheckInFrequency? = nil
    
    var canComplete: Bool {
        if isUnified {
            // unifiedFrequency가 nil이 아니고 .none이 아닐때 true
            return unifiedFrequency != nil && unifiedFrequency != CheckInFrequency.none
        } else {
            // 각각의 사람 frequency가 nil 아니고 .none 아닐떄
            return people.allSatisfy {
                $0.frequency != nil && $0.frequency != CheckInFrequency.none
            }
        }
    }
    
    func toggleUnifiedFrequency(_ enabled: Bool) {
        isUnified = enabled
    }
    
    func updateFrequency(for person: Friend, to frequency: CheckInFrequency) {
        guard let index = people.firstIndex(of: person) else { return }
        people[index].frequency = frequency
    }
    
    func applyUnifiedFrequency(_ frequency: CheckInFrequency) {
        unifiedFrequency = frequency
        if isUnified {
            people = people.map {
                Friend(id: $0.id, name: $0.name, image: $0.image, source: $0.source, frequency: frequency)
            }
        }
    }
    
    // RegisterViewModel에서 선택한 연락처 받아오는 메소드
    func setPeople(from contacts: [Friend]) {
        self.people = contacts.map {
            Friend(id: $0.id, name: $0.name, image: $0.image, source: $0.source, frequency: $0.frequency)
        }
    }
}
