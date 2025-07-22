import Siren

class SirenManager {
    static let shared = SirenManager()
    
    private init() {}
    
    func configureSirenAllCritical() {
        // 알림 시점 정의
        // annoying: (항상 확인) / 다음에 업데이트
        // critical: (항상 확인) / 즉시 업데이트
        // default: (하루 한 번) / 다음에 업데이트 / 버전 건너 뜀
        // persistent: (하루 한 번) / 다음에 업데이트
        // hinting: (일주일 한 번) / 다음에 업데이트
        // relaxed: (일주일 한 번) / 다음에 업데이트 / 버전 건너 뜀
        let siren = Siren.shared
        siren.rulesManager = RulesManager(
            majorUpdateRules: .critical,
            minorUpdateRules: .critical,
            patchUpdateRules: .critical,
            revisionUpdateRules: .relaxed,
            showAlertAfterCurrentVersionHasBeenReleasedForDays: 0
        )
        siren.wail()
    }
}
