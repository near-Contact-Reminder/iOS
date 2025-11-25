import Foundation

// MARK: - Terms Catalog
struct TermResponse: Decodable, Identifiable {
    let termId: Int
    let title: String
    let version: String
    let isRequired: Bool
    let detailUrl: String?
    
    var id: Int { termId }
}

// MARK: - My Terms Agreements
struct MyTermsAgreementResponse: Decodable {
    let agreements: [TermAgreementResponse]
}

struct TermAgreementResponse: Decodable, Identifiable {
    let termId: Int
    let title: String
    let version: String
    let isRequired: Bool
    let isAgreed: Bool
    let agreedAt: String?
    
    var id: Int { termId }
}

// MARK: - Agreement Submission
struct TermsAgreementRequest: Encodable {
    let agreements: [TermAgreementRequest]
}

struct TermAgreementRequest: Encodable {
    let termId: Int
    let isAgreed: Bool
}
