import SwiftUI
import Firebase

@main
struct SwypApp2ndApp: App {
    
    init() {
        NotificationManager.shared.requestPermissionIfNeeded()
        FirebaseApp.configure()
        AnalyticsManager.shared.setEntryChannel("direct")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
