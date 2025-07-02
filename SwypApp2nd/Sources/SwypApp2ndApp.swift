import SwiftUI
import Firebase

@main
struct SwypApp2ndApp: App {
    
    init() {
        FirebaseApp.configure()
#if !DEBUG
        AnalyticsManager.shared.setEntryChannel("direct")
#endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
