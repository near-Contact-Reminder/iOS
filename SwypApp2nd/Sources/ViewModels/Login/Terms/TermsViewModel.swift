import SwiftUI

final class TermsViewModel: ObservableObject {
    
    /// 서비스 이용 약관 상세 동의
    @Published var isServiceTermsAgreed: Bool = false
    
    /// 개인 정보 수집 및 이용 동의
    @Published var isPersonalInfoTermsAgreed: Bool = false
    
    /// 개인 정보 처리방침 상세
    @Published var isPrivacyPolicyAgreed: Bool = false
    
    /// 약관 전체 동의
    @Published var isAllAgreed: Bool = false {
        didSet {
            if isAllAgreed {
                self.isServiceTermsAgreed = true
                self.isPersonalInfoTermsAgreed = true
                self.isPrivacyPolicyAgreed = true
            }
        }
    }
    
    /// 약관 전체 동의 체크 메소드
    func toggleAllAgreed() {
        let shouldAgree = !isAllAgreed
        isAllAgreed = shouldAgree
        isServiceTermsAgreed = shouldAgree
        isPersonalInfoTermsAgreed = shouldAgree
        isPrivacyPolicyAgreed = shouldAgree
    }
    
    /// 개별 항목이 모두 동의되었는지 확인 후 전체 동의 상태를 갱신
    private func checkAllAgreed() {
        isAllAgreed = isServiceTermsAgreed &&
        isPersonalInfoTermsAgreed &&
        isPrivacyPolicyAgreed
    }
    
    /// 약관 전체 동의 확인
    var canProceed: Bool {
        isServiceTermsAgreed &&
        isPersonalInfoTermsAgreed &&
        isPrivacyPolicyAgreed
    }
}
