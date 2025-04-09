import Foundation

extension Date {
    func nextCheckInDate(for frequency: CheckInFrequency) -> String {
        let calendar = Calendar.current
        var nextDate: Date?

        switch frequency {
        case .daily:
            nextDate = calendar.date(byAdding: .day, value: 1, to: self)
        case .weekly:
            nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: self)
        case .biweekly:
            nextDate = calendar.date(byAdding: .weekOfYear, value: 2, to: self)
        case .monthly:
            nextDate = calendar.date(byAdding: .month, value: 1, to: self)
        case .semiAnnually:
            nextDate = calendar.date(byAdding: .month, value: 6, to: self)
        default:
            return "-"
        }

        guard let date = nextDate else { return "-" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M/d EEE"

        return formatter.string(from: date)
    }

    func weekdayKorean() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }
}
