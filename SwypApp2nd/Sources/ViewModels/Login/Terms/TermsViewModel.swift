import SwiftUI

struct TermItem: Identifiable, Equatable {
    let termId: Int
    let title: String
    let version: String
    let isRequired: Bool
    var isAgreed: Bool
    var agreedAt: String?
    var detailURL: String?
    
    var id: Int { termId }
}

enum TermsViewModelError: LocalizedError {
    case missingToken
    case emptyAgreements
    case underlying(Error)
    
    var errorDescription: String? {
        switch self {
        case .missingToken:
            return "로그인 정보를 찾을 수 없습니다. 다시 로그인해 주세요."
        case .emptyAgreements:
            return "약관을 선택해 주세요."
        case .underlying(let error):
            return error.localizedDescription
        }
    }
}

final class TermsViewModel: ObservableObject {
    @Published private(set) var terms: [TermItem] = []
    @Published var isLoading: Bool = false
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String?
    
    private let service: BackEndAuthService
    private var didLoadOnce = false
    
    private let serviceTermsURL = TermsViewModel.infoURL(for: "SERVICE_AGREED_TERMS_URL")
    private let personalInfoTermsURL = TermsViewModel.infoURL(for: "PERSONAL_INFO_TERMS_URL")
    private let privacyPolicyTermsURL = TermsViewModel.infoURL(for: "PRIVACY_POLICY_TERMS_URL")
    
    init(service: BackEndAuthService = .shared) {
        self.service = service
    }
    
    // MARK: - Public API
    func loadTerms(force: Bool = false) {
        guard force || !didLoadOnce else { return }
        didLoadOnce = true
        fetchTerms(forceReload: force)
    }
    
    func refresh() {
        fetchTerms(forceReload: true)
    }
    
    var isAllAgreed: Bool {
        !terms.isEmpty && terms.allSatisfy { $0.isAgreed }
    }
    
    var canProceed: Bool {
        !terms.isEmpty && terms.filter { $0.isRequired }.allSatisfy { $0.isAgreed }
    }
    
    func binding(for term: TermItem) -> Binding<Bool> {
        Binding<Bool>(
            get: { [weak self] in
                self?.terms.first(where: { $0.termId == term.termId })?.isAgreed ?? false
            },
            set: { [weak self] newValue in
                self?.updateAgreement(termId: term.termId, isAgreed: newValue)
            }
        )
    }
    
    func toggleAllAgreed() {
        let shouldAgree = !isAllAgreed
        updateAllAgreements(to: shouldAgree)
    }
    
    func updateAllAgreements(to value: Bool) {
        terms = terms.map { term in
            var updated = term
            updated.isAgreed = value
            return updated
        }
    }
    
    func submitAgreements(completion: @escaping (Result<Void, TermsViewModelError>) -> Void) {
        guard !isSubmitting else { return }
        guard canProceed else {
            completion(.failure(.emptyAgreements))
            errorMessage = TermsViewModelError.emptyAgreements.errorDescription
            return
        }
        guard let token = TokenManager.shared.get(for: .server) else {
            completion(.failure(.missingToken))
            errorMessage = TermsViewModelError.missingToken.errorDescription
            return
        }
        let selectedAgreements = terms
            .filter { $0.isAgreed }
            .map { TermAgreementRequest(termId: $0.termId, isAgreed: $0.isAgreed) }
        guard !selectedAgreements.isEmpty else {
            completion(.failure(.emptyAgreements))
            errorMessage = TermsViewModelError.emptyAgreements.errorDescription
            return
        }
        isSubmitting = true
        errorMessage = nil
        service.submitTermsAgreements(accessToken: token, agreements: selectedAgreements) { [weak self] result in
            guard let self = self else { return }
            self.isSubmitting = false
            switch result {
            case .success:
                print("🟢 [TermsViewModel] 약관 동의 제출 성공")
                completion(.success(()))
            case .failure(let error):
                print("🔴 [TermsViewModel] 약관 동의 제출 실패: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
                completion(.failure(.underlying(error)))
            }
        }
    }
    
    func detailURL(for term: TermItem) -> String? {
        if let detailURL = term.detailURL {
            return detailURL
        }
        return fallbackURL(for: term.title)
    }
    
    // MARK: - Private Helpers
    private func fetchTerms(forceReload: Bool = false) {
        if forceReload {
            didLoadOnce = true
        }
        isLoading = true
        errorMessage = nil
        service.fetchTermsList { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let responses):
                let baseItems = responses.map { response in
                    TermItem(
                        termId: response.termId,
                        title: response.title,
                        version: response.version,
                        isRequired: response.isRequired,
                        isAgreed: false,
                        agreedAt: nil,
                        detailURL: response.detailUrl ?? self.fallbackURL(for: response.title)
                    )
                }
                self.fetchMyAgreements(using: baseItems)
            case .failure(let error):
                print("🔴 [TermsViewModel] 약관 목록 조회 실패: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
                self.terms = []
                self.isLoading = false
            }
        }
    }
    
    private func fetchMyAgreements(using baseItems: [TermItem]) {
        guard let token = TokenManager.shared.get(for: .server) else {
            print("🔴 [TermsViewModel] 서버 토큰을 찾을 수 없습니다.")
            self.errorMessage = TermsViewModelError.missingToken.errorDescription
            self.terms = baseItems
            self.isLoading = false
            return
        }
        service.fetchMyTermsAgreements(accessToken: token) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            switch result {
            case .success(let response):
                print("🟢 [TermsViewModel] 약관 동의 상태 동기화 성공")
                var mergedItems = baseItems
                response.agreements.forEach { agreement in
                    if let index = mergedItems.firstIndex(where: { $0.termId == agreement.termId }) {
                        mergedItems[index].isAgreed = agreement.isAgreed
                        mergedItems[index].agreedAt = agreement.agreedAt
                    } else {
                        let newItem = TermItem(
                            termId: agreement.termId,
                            title: agreement.title,
                            version: agreement.version,
                            isRequired: agreement.isRequired,
                            isAgreed: agreement.isAgreed,
                            agreedAt: agreement.agreedAt,
                            detailURL: self.fallbackURL(for: agreement.title)
                        )
                        mergedItems.append(newItem)
                    }
                }
                self.terms = mergedItems.sorted { $0.termId < $1.termId }
            case .failure(let error):
                print("🔴 [TermsViewModel] 약관 동의 상태 조회 실패: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
                self.terms = baseItems
            }
        }
    }
    
    private func updateAgreement(termId: Int, isAgreed: Bool) {
        guard let index = terms.firstIndex(where: { $0.termId == termId }) else { return }
        terms[index].isAgreed = isAgreed
    }
    
    private func fallbackURL(for title: String) -> String? {
        if title.contains("서비스") {
            return serviceTermsURL
        } else if title.contains("수집") {
            return personalInfoTermsURL
        } else if title.contains("처리") {
            return privacyPolicyTermsURL
        }
        return nil
    }
    
    private static func infoURL(for key: String) -> String? {
        guard let host = Bundle.main.infoDictionary?[key] as? String, !host.isEmpty else {
            return nil
        }
        return host.hasPrefix("http") ? host : "https://\(host)"
    }

     func findTerm(byKeyword keyword: String) -> TermItem? {
         if keyword.contains("서비스") {
             return terms.first { $0.title.contains("서비스") }
         } else if keyword.contains("수집") {
             return terms.first { $0.title.contains("수집") }
         } else if keyword.contains("처리") {
             return terms.first { $0.title.contains("처리") }
         }
         return nil
     }

    /// 제목으로 약관 정보를 찾아 반환 (약관 객체가 없더라도 fallback URL이 있으면 반환)
    func getAgreementDetail(for title: String) -> (term: TermItem?, urlString: String)? {
        // 1. 서버에서 가져온 약관 목록 중 제목이 일치하는 것이 있는지 확인
        let term = findTerm(byKeyword: title)
        
        // 2. 우선순위에 따라 URL 결정
        //   - 1순위: 서버 약관 객체의 detail URL (detailURL 함수가 있다고 가정)
        //   - 2순위: fallbackURL(for:)를 통한 로컬 정의 URL
        let urlString = (term != nil ? detailURL(for: term!) : nil) ?? fallbackURL(for: title)
        
        // 3. URL이 최종적으로 없다면 nil 반환
        guard let finalURL = urlString else { return nil }
        
        return (term: term, urlString: finalURL)
    }
    
}
