import SwiftUI

/// NavigationStack의 path를 안전하게 관리하기 위한 헬퍼 extension
extension Binding where Value == [AppRoute] {
    /// 빈 배열 체크 후 안전하게 마지막 경로를 제거합니다.
    /// path가 비어있으면 아무 동작도 하지 않습니다.
    func safeRemoveLast() {
        guard !wrappedValue.isEmpty else {
            #if DEBUG
            print("⚠️ [NavigationPath] Attempted removeLast() from empty path")
            #endif
            return
        }
        wrappedValue.removeLast()
    }
    
    /// 현재 경로가 특정 route로 끝나는지 확인하고 안전하게 제거합니다.
    /// - Parameter route: 제거할 route (현재 path의 마지막 요소와 일치해야 함)
    func safeRemoveLast(ifLastIs route: AppRoute) {
        if wrappedValue.last == route {
            safeRemoveLast()
        }
    }
}

