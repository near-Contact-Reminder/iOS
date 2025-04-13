import Foundation
import UIKit

// TODO: - Friend로 변경 관계, 생일, 기념일, 메모, 챙김기록..? 추가.
struct Friend: Identifiable, Equatable, Hashable {
    var id: UUID
    var name: String
    var image: UIImage?
    var imageURL: String?
    var source: ContactSource
    var frequency: CheckInFrequency?
    var remindCategory: RemindCategory?
    var nextContactAt: Date? // 다음 연락 예정일
    var lastContactAt: Date? // 마지막 연락 일
    var checkRate: Int? // 챙김률
    var position: Int? // 내사람들 리스트 순서
}

enum RemindCategory {
    case message
    case birth
    case anniversary
}

enum ContactSource: Codable {
    case phone, kakao
}
