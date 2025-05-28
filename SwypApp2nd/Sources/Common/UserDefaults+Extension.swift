import Foundation

extension UserDefaults {
    private enum Keys {
        static let didSeeOnboarding = "didSeeOnboarding"
    }

    var didSeeOnboarding: Bool {
        get { bool(forKey: Keys.didSeeOnboarding) }
        set { set(newValue, forKey: Keys.didSeeOnboarding) }
    }
}
