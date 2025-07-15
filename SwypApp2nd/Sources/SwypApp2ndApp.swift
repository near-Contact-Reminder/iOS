import SwiftUI
import Firebase

@main
struct SwypApp2ndApp: App {
    
    init() {
        FirebaseApp.configure()
#if DEBUG
        Analytics.setAnalyticsCollectionEnabled(false)
#else
        Analytics.setAnalyticsCollectionEnabled(true)
#endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
